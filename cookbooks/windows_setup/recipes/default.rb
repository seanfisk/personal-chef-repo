# -*- coding: utf-8 -*-
#
# Cookbook Name:: windows_setup
# Recipe:: default
#
# Author:: Sean Fisk <sean@seanfisk.com>
# Copyright:: Copyright (c) 2014, Sean Fisk
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# NOTE: powershell_script doesn't support the 'command' attribute. Argh...!

require 'chef/mixin/shell_out'
extend Chef::Mixin::ShellOut

directory node['windows_setup']['scripts_dir'] do
  recursive true
end
# The 'env' resource works for system environment variables, but apparently not
# for user environment variables. The 'windows_path' resource in the windows
# cookbook appears to only work for the system path. Since this is a per-user
# scripts directory, it makes sense to put in in the user environment variable.
# We therefore resort to this PowerShell hack, which is ugly but works.
var = 'Path'
scope = 'User'
path = node['windows_setup']['scripts_dir']
get_var_command = (
  "[Environment]::GetEnvironmentVariable('#{var}', '#{scope}')")
powershell_script "add #{path} to the #{scope} #{var}" do
  code "[Environment]::SetEnvironmentVariable('#{var}', "\
       "#{get_var_command} + ';' + '#{path}', '#{scope}')"
  not_if "#{get_var_command}.Split(';') -Contains '#{path}'"
end

# Fails out with insufficient permissions. I guess we'll just assume it exists
# for now.
#
# directory node['windows_setup']['startup_dir'] do
#   recursive true
# end

include_recipe 'chocolatey'

node['windows_setup']['packages'].each do |pkg_name|
  chocolatey pkg_name
end

# Swap Caps Lock and Control using AutoHotKey.
script_base = 'SwapCapsLockControl'
script_name = "#{script_base}.ahk"
script_path = "#{node['windows_setup']['scripts_dir']}\\#{script_name}"
shortcut_path = "#{node['windows_setup']['startup_dir']}\\#{script_base}.lnk"
cookbook_file script_name do
  path script_path
end
windows_shortcut shortcut_path do
  target script_path
  description 'Swap Caps Lock and Control on startup'
end

# Gibo
script_name = 'gibo.bat'
remote_file 'download and install Gibo' do
  # This file will likely change, so don't provide a checksum.
  source 'https://raw.githubusercontent.com/simonwhitaker/gibo/master/' +
    script_name
  path "#{node['windows_setup']['scripts_dir']}\\#{script_name}"
end

# Gitignore from dotfiles
# TODO: This is kind of ugly; the dotfiles repo should really be on Windows.
# Note: This file will have LF line endings. Not necessarily ideal...
remote_file 'download my .gitconfig' do
  source 'https://raw.githubusercontent.com/'\
         'seanfisk/dotfiles/master/dotfiles/gitconfig'
  path "#{node['windows_setup']['home']}\\.gitconfig"
end

# Install PsGet. There is a Chocolatey package for this, but as of 2015-03-06
# it seems outdated.
powershell_script 'install PsGet' do
  code '(New-Object Net.WebClient).DownloadString('\
       '"http://psget.net/GetPsGet.ps1") | Invoke-Expression'
  only_if '(Get-Module -ListAvailable -Name PsGet) -eq $null'
end

node['windows_setup']['psget_modules'].each do |mod_name|
  # Use string interpolation in the name instead of concatenation, else
  # Foodcritic will complain about the guard not acting as expected.
  powershell_script "install PsGet module '#{mod_name}'" do
    code "Install-Module '#{mod_name}'"
    only_if "(Get-PsGetModuleInfo -ModuleName '#{mod_name}') -eq $null"
  end
end

# Install paste program
windows_zipfile 'download and install paste program' do
  path node['windows_setup']['scripts_dir']
  # TODO: This comes from a somewhat questionable source...
  source 'http://www.c3scripts.com/tutorials/msdos/paste.zip'
  # We've provided a checksum as this file is unlikely to change.
  checksum 'fd8034ed96d1e18be508b61c5732e91c24c6876229bc78ef9cd617682e37c493'
  action :unzip
  not_if { File.exist?("#{node['windows_setup']['scripts_dir']}/paste.exe") }
end

# Mixlib::ShellOut doesn't support arrays on Windows... Ugh.
PS_PROFILE_PATH = shell_out!(
  'powershell -NoLogo -NonInteractive -NoProfile -Command $profile'
).stdout.rstrip

cookbook_file 'Writing PowerShell profile ' + PS_PROFILE_PATH do
  source 'profile.ps1'
  path PS_PROFILE_PATH
end

# For is_package_installed?
::Chef::Recipe.send(:include, Windows::Helper)
# This can't be inside the not_if guard in the registry_key resource, otherwise
# the method won't be found.
is_boot_camp_installed = is_package_installed?('Boot Camp Services')

# Note: Requires logout to take effect
registry_key 'enable standard function key behavior' do
  key 'HKEY_CURRENT_USER\Software\Apple Inc.\Apple Keyboard Support'
  values [{ name: 'OSXFnBehavior',
            type: :dword,
            data: 0
          }]
  only_if { is_boot_camp_installed }
end

EXPLORER_KEY =
  'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer'

registry_key 'configure the taskbar' do
  key EXPLORER_KEY
  values [
    # "Always show all icons and notifications on the taskbar"
    { name: 'EnableAutoTray',
      type: :dword,
      data: 0
    }
  ]
  notifies :run, 'powershell_script[restart Windows Explorer]'
end

# http://stackoverflow.com/a/8110982/879885
registry_key 'configure Windows Explorer' do
  key "#{EXPLORER_KEY}\\Advanced"
  values [
    # Show hidden files
    { name: 'Hidden',
      type: :dword,
      data: 1
    },
    # Don't hide file extensions for known file types
    { name: 'HideFileExt',
      type: :dword,
      data: 0
    },
    # But don't show OS files
    { name: 'ShowSuperHidden',
      type: :dword,
      data: 0
    }
  ]
  notifies :run, 'powershell_script[restart Windows Explorer]'
end

powershell_script 'restart Windows Explorer' do
  code 'Stop-Process -Name explorer'
  # Windows Explorer restarts automatically
  action :nothing
end
