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

require 'mixlib/shellout'

directory node['windows_setup']['scripts_dir'] do
  recursive true
end
# The 'env' resource works for system environment variables, but apparently not
# for user environment variables. Since this is a per-user scripts directory,
# it makes sense to put in in the user environment variable.
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

# TODO: As of the chocolatey cookbook version 0.2.0, the cookbook does not
# recognize Chocolatey 0.9.9.x and downgrades to 0.9.8.x when run. However,
# this leaves Chocolatey in a weird state where 'choco list -lo' will still
# list the chocolatey package at version 0.9.9.x. If automatic update is
# enabled (default), then the cookbook installs the old version and immediately
# tries to upgrade to the newer one, and sometimes fails.
#
# So currently, after running chef-client, for the latest version of Chocolatey
# you'll have to run:
#
#     choco install -force chocolatey
#
# Follow the issue here:
# <https://github.com/chocolatey/chocolatey-cookbook/issues/34>
node.default['chocolatey']['upgrade'] = false

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
# it seems outdated. This install command seems to be idempotent.
powershell_script 'install PsGet' do
  code '(New-Object Net.WebClient).DownloadString('\
       '"http://psget.net/GetPsGet.ps1") | Invoke-Expression'
end

node['windows_setup']['psget_modules'].each do |mod_name|
  powershell_script 'install PsGet module ' + mod_name do
    code 'Install-Module ' + mod_name
  end
end

# Mixlib::ShellOut doesn't support arrays on Windows... Ugh.
ps_proc = Mixlib::ShellOut.new(
  'powershell -NoLogo -NonInteractive -NoProfile -Command $profile')
ps_proc.run_command
PS_PROFILE_PATH = ps_proc.stdout.rstrip

cookbook_file 'Writing PowerShell profile ' + PS_PROFILE_PATH do
  source 'profile.ps1'
  path PS_PROFILE_PATH
end
