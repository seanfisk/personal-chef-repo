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
file "#{node['windows_setup']['scripts_dir']}\\README.txt" do
  content <<EOF
This directory is for command-line applications or scripts that will be added \
to the executable Path. These programs do not install through a Windows \
installer and do not have an entry in the Control Panel.
EOF
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
# paste program depends on .NET 3.5
# Also possible to install with Chocolatey, but Chef-native seems better.
windows_feature 'NetFx3' do
  action :install
  all true
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

# Disable the startup sound
# See here http://www.sevenforums.com/tutorials/179448-startup-sound-enable-disable.html
# I've elected to have the startup sound always disabled. There's really no
# point in allowing it to be edited via the GUI when it will be reset the
# next we converge anyway.
registry_key 'disable the startup sound' do
  key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies' \
    '\System'
  values [{ name: 'DisableStartupSound', type: :dword, data: 1 }]
end
registry_key 'disable editing of startup sound' do
  key 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion' \
    '\Authentication\LogonUI\BootAnimation'
  values [{ name: 'DisableStartupSound', type: :dword, data: 0 }]
end

# Windows doesn't set this automatically, so set it here. Change if I move ;)
TIME_ZONE = 'Eastern Standard Time'
# See here http://www.windows-commandline.com/set-time-zone-from-command-line/
# It's possible to manipulate the time zone registry key, but this misses keys
# that get changed by the GUI and doesn't automatically update Windows
# Explorer. tzutil does both.
# Note: We've tried an array argument with execute's command... doesn't work :(
powershell_script 'set time zone' do
  code "tzutil /s '#{TIME_ZONE}'"
  not_if "(tzutil /g) -eq '#{TIME_ZONE}'"
end

powershell_script 'restart Windows Explorer' do
  code 'Stop-Process -Name explorer'
  # Windows Explorer restarts automatically
  action :nothing
end

powershell_script 'update Powershell help' do
  # There is AFAIK no way to check to see if the help needs to be updated,
  # making it impossible to make this resource idempotent. However, Update-Help
  # has its own check in that it only runs once per day (unless you pass
  # -Force). We don't have anything better, so we'll settle for this.
  code 'Update-Help'
end

# Custom applications
directory node['windows_setup']['apps_dir'] do
  recursive true
end
file "#{node['windows_setup']['apps_dir']}\\README.txt" do
  content <<EOF
This directory is for portable applications that do not install through a \
Windows installer and do not have an entry in the Control Panel.
EOF
end

FLASH_PLAYER_VERSION = '18'
flash_player_install_path =
  "#{node['windows_setup']['apps_dir']}\\flashplayer_sa.exe"
remote_file 'download and install Flash Player projector' do
  source 'https://fpdownload.macromedia.com/pub/flashplayer/updaters/' \
    "#{FLASH_PLAYER_VERSION}/flashplayer_#{FLASH_PLAYER_VERSION}_sa.exe"
  path flash_player_install_path
  checksum 'f93ceb1c4dfff8934429c72c284058bc85061be77a6fd993372a89e00a07c525'
end
windows_shortcut "#{node['windows_setup']['desktop_dir']}\\Flash Player.lnk" do
  target flash_player_install_path
  description 'Launch the Flash Player projector'
end

powerplan_cache_path = "#{Chef::Config[:file_cache_path]}\\powerplan-setup.exe"
remote_file 'download Power Plan Assistant' do
  source 'http://cdn-us.filecluster.com/PowerPlanAssistant/' \
         'Power_Plan_Assistant_32a_Setup_09032015.exe'
  path powerplan_cache_path
  checksum 'abf029e8240b80ad42be8464757a6d3f6cd868fdb9e08800741b2fbc9f51acf4'
  # They tried to be clever, but they couldn't fool me, no sir.
  headers 'Referer' => 'http://www.filecluster.com/downloads/' \
                       'Power-Plan-Assistant-for-Windows-7.html'
end

windows_package 'Power Plan Assistant' do
  source powerplan_cache_path
  # XXX: Unfortunately, this doesn't work. It was apparently not
  # enabled when the installer was built. Clicking through the dialogs
  # is manual, but we'll leave it in here any way so that we ensure it
  # gets installed.
  #
  # See 'Silent Command-Line parameter' here:
  # http://www.createinstall.com/help/settings.html
  installer_type :custom
  options '-silent'
end
# No way of which I know to automate turning off the keyboard
# backlight for the first time, which is the whole reason we installed
# this program. Luckily, it's persistent.

# Power Plan Assistant is required for Trackpad++.
trackpad_cache_path = "#{Chef::Config[:file_cache_path]}\\trackpad-setup.exe"
remote_file 'download Trackpad++' do
  source 'http://cdn-us.filecluster.com/TrackpadDriverandControlModule/' \
         'Trackpad_Plus_Plus_Driver_Control_Module_Setup_31d_09032015.exe'
  path trackpad_cache_path
  checksum '1041d049690852cb02f3ab1aee61a089ae0e239c5a11d3e439fb9aaaee08435e'
  headers 'Referer' => 'http://www.filecluster.com/downloads/' \
                       'Trackpad-Driver-and-Control-Module.html'
end
windows_package 'Trackpad++' do
  source trackpad_cache_path
  # XXX: See above
  installer_type :custom
  options '-silent'
end

windows_package 'Python 3.5.0rc4 (64-bit)' do
  source 'https://www.python.org/ftp/python/3.5.0/python-3.5.0rc4-amd64.exe'
  installer_type :custom
  # https://docs.python.org/3.5/using/windows.html#installation-steps
  #
  # XXX: /quiet and /passive fail to install the package correctly
  # (use '/log mylog.txt' as an argument to the installer to see
  # why). Because of this, we're just using SimpleInstall. It has a
  # GUI, but it's only one click, and better than nothing.
  #
  # Install just for me. This installer is also smart enough to add to
  # the User Path under the just-for-me install. Yay!
  options 'InstallAllUsers=0 CompileAll=1 PrependPath=1 ' \
          'InstallLauncherAllUsers=0 SimpleInstall=1 ' \
          'SimpleInstallDescription="Sean\'s per-user install"'
end
