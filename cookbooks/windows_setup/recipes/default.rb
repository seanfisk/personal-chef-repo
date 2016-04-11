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

require 'json'

# For is_package_installed?
::Chef::Recipe.send(:include, Windows::Helper)

def add_to_user_path(path)
  # The 'env' resource works for system environment variables, but
  # apparently not for user environment variables. The 'windows_path'
  # resource in the windows cookbook appears to only work for the
  # system path. Since we have per-user directories we want to add, it
  # makes sense to put in in the user environment variable.  We
  # therefore resort to this PowerShell hack, which is ugly but works.
  var = 'Path'
  scope = 'User'
  get_var_command = (
    "[Environment]::GetEnvironmentVariable('#{var}', '#{scope}')")
  powershell_script "add #{path} to the #{scope} #{var}" do
    code "[Environment]::SetEnvironmentVariable('#{var}', "\
         "#{get_var_command} + ';' + '#{path}', '#{scope}')"
    not_if "#{get_var_command}.Split(';') -Contains '#{path}'"
  end
end

def add_to_system_path(path)
  windows_path "add #{path} to the System Path" do
    path path
    action :add
  end
end

def registry_get_value(key, value_name)
  # TODO: Some error checking for a non-existent key would be nice
  registry_get_values(key).select do |value|
    value[:name] == value_name
  end[0][:data]
end

directory node.windows_setup.scripts_dir do
  recursive true
end
file "#{node.windows_setup.scripts_dir}\\README.txt" do
  content <<EOF
This directory is for command-line applications or scripts that will be added \
to the executable Path. These programs do not install through a Windows \
installer and do not have an entry in the Control Panel.
EOF
end
add_to_user_path node.windows_setup.scripts_dir

# Fails out with insufficient permissions. I guess we'll just assume it exists
# for now.
#
# directory node.windows_setup.startup_dir do
#   recursive true
# end

include_recipe 'chocolatey'

node.windows_setup.packages.each do |pkg_name|
  chocolatey pkg_name
end

# Enable Chocolatey features.
lambda do
  features = {}
  feature_cmd = 'choco feature list'
  powershell_out!(feature_cmd).stdout.lines do |line|
    match = /(\w+) - \[(En|Dis)abled\]/.match(line)
    Chef::Application.fatal!(
      "Unexpected output format for '#{feature_cmd}'") unless match
    features[match[1]] = match[2] == 'En'
  end
  node.windows_setup.chocolatey.features.each do |feature|
    powershell_script "enable Chocolatey feature '#{feature}'" do
      code "choco feature enable --name='#{feature}'"
      not_if { features[feature] }
    end
  end
end.call

# Add AutoHotkey compiler (Ahk2Exe) to System Path.
add_to_system_path(
  ::File.dirname(
    registry_get_value(
      'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths' \
      '\Ahk2Exe.exe',
      # This gets the default key.
      '')))

# Swap Caps Lock and Control using a registry hack. We previously used
# AutoHotkey to do this, but since it used hotstrings, it installed a keyboard
# hook which interfered with the Diablo II macros. See notes in that project
# for more information.
#
# See http://emacswiki.org/emacs/MovingTheCtrlKey#toc20
lambda do
  reboot_reason = 'apply Caps Lock and Control swap registry hack'
  registry_key 'swap Caps Lock and Control keys using registry hack' do
    key 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Keyboard Layout'
    values [{ name: 'Scancode Map',
              type: :binary,
              data: "\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\x00\x00" \
                    "\x1d\x00\x3a\x00\x3a\x00\x1d\x00\x00\x00\x00\x00" }]
    notifies :request_reboot, "reboot[#{reboot_reason}]",
             # This means "deliver the notification immediately", not "reboot
             # immediately". Apparently :delayed isn't even supported.
             :immediately
  end

  reboot reboot_reason do
    reason 'Need to reboot to ' + reboot_reason
    action :nothing
  end
end

# Gibo
remote_file 'download and install Gibo' do
  script_name = 'gibo.bat'
  # This file will likely change, so don't provide a checksum.
  source 'https://raw.githubusercontent.com/simonwhitaker/gibo/master/' +
    script_name
  path "#{node.windows_setup.scripts_dir}\\#{script_name}"
end

# Gitignore from dotfiles
# TODO: This is kind of ugly; the dotfiles repo should really be on Windows.
# Note: This file will have LF line endings. Not necessarily ideal...
remote_file 'download my .gitconfig' do
  source 'https://raw.githubusercontent.com/'\
         'seanfisk/dotfiles/master/dotfiles/gitconfig'
  path "#{node.windows_setup.home}\\.gitconfig"
end

# Install PsGet. There is a Chocolatey package for this, but as of 2015-03-06
# it seems outdated.
powershell_script 'install PsGet' do
  code '(New-Object Net.WebClient).DownloadString('\
       '"http://psget.net/GetPsGet.ps1") | Invoke-Expression'
  only_if '(Get-Module -ListAvailable -Name PsGet) -eq $null'
end

node.windows_setup.psget.modules.each do |mod_name|
  # Use string interpolation in the name instead of concatenation, else
  # Foodcritic will complain about the guard not acting as expected.
  powershell_script "install PsGet module '#{mod_name}'" do
    code "Install-Module '#{mod_name}'"
    only_if "(Get-PsGetModuleInfo -ModuleName '#{mod_name}') -eq $null"
  end
end

# Install paste program
windows_zipfile 'download and install paste program' do
  path node.windows_setup.scripts_dir
  # TODO: This comes from a somewhat questionable source...
  source 'http://www.c3scripts.com/tutorials/msdos/paste.zip'
  # We've provided a checksum as this file is unlikely to change.
  checksum 'fd8034ed96d1e18be508b61c5732e91c24c6876229bc78ef9cd617682e37c493'
  action :unzip
  not_if { File.exist?("#{node.windows_setup.scripts_dir}/paste.exe") }
end
# paste program depends on .NET 3.5
# Also possible to install with Chocolatey, but Chef-native seems better.
windows_feature 'NetFx3' do
  action :install
  all true
end

lambda do
  # Mixlib::ShellOut doesn't support arrays on Windows... Ugh.
  profile_path = shell_out!(
    "#{node.windows_setup.ps_args} $profile"
  ).stdout.rstrip

  cookbook_file 'Writing PowerShell profile ' + profile_path do
    source 'profile.ps1'
    path profile_path
  end
end.call

lambda do
  # This can't be inside the not_if guard in the registry_key resource,
  # otherwise the method won't be found.
  boot_camp_is_installed = is_package_installed?('Boot Camp Services')

  # Note: Requires logout to take effect
  registry_key 'enable standard function key behavior' do
    key 'HKEY_CURRENT_USER\Software\Apple Inc.\Apple Keyboard Support'
    values [{ name: 'OSXFnBehavior',
              type: :dword,
              data: 0
            }]
    only_if { boot_camp_is_installed }
  end
end.call

registry_key 'configure the taskbar' do
  key node.windows_setup.explorer_registry_key
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
  key "#{node.windows_setup.explorer_registry_key}\\Advanced"
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

# Windows doesn't set the time zone automatically, so set it here. Change if I
# move ;)
#
# See here http://www.windows-commandline.com/set-time-zone-from-command-line/
# It's possible to manipulate the time zone registry values, but this misses
# values that get changed by the GUI and doesn't automatically update Windows
# Explorer. tzutil does both.
# Note: We've tried an array argument with execute's command... doesn't work :(
powershell_script 'set time zone' do
  code "tzutil /s '#{node.windows_setup.time_zone}'"
  not_if "(tzutil /g) -eq '#{node.windows_setup.time_zone}'"
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
directory node.windows_setup.apps_dir do
  recursive true
end
file "#{node.windows_setup.apps_dir}\\README.txt" do
  content <<EOF
This directory is for portable applications that do not install through a \
Windows installer and do not have an entry in the Control Panel.
EOF
end

lambda do
  version = '18'
  install_path = "#{node.windows_setup.apps_dir}\\flashplayer_sa.exe"
  remote_file 'download and install Flash Player projector' do
    source 'https://fpdownload.macromedia.com/pub/flashplayer/updaters/' \
           "#{version}/flashplayer_#{version}_sa.exe"
    path install_path
    checksum 'f93ceb1c4dfff8934429c72c284058bc85061be77a6fd993372a89e00a07c525'
  end
  windows_shortcut "#{node.windows_setup.desktop_dir}\\Flash Player.lnk" do
    target install_path
    description 'Launch the Flash Player projector'
  end
end.call

lambda do
  cache_path = "#{Chef::Config[:file_cache_path]}\\powerplan-setup.exe"
  remote_file 'download Power Plan Assistant' do
    # This URL [should] always redirect to the latest download.
    source 'http://www.filecluster.com/download-link-4/113379.html'
    path cache_path
    # They tried to be clever, but they couldn't fool me, no sir.
    headers 'Referer' => 'http://www.filecluster.com/downloads/' \
                         'Power-Plan-Assistant-for-Windows-7.html'
  end

  windows_package 'Power Plan Assistant' do
    source cache_path
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
end.call

lambda do
  # Power Plan Assistant is required for Trackpad++.
  cache_path = "#{Chef::Config[:file_cache_path]}\\trackpad-setup.exe"
  remote_file 'download Trackpad++' do
    # This URL [should] always redirect to the latest download.
    source 'http://www.filecluster.com/download-link-4/160247.html'
    path cache_path
    headers 'Referer' => 'http://www.filecluster.com/downloads/' \
                         'Trackpad-Driver-and-Control-Module.html'
  end
  windows_package 'Trackpad++' do
    source cache_path
    # XXX: See above
    installer_type :custom
    options '-silent'
  end
end.call

windows_package 'Python 3.5.0 (64-bit)' do
  source 'https://www.python.org/ftp/python/3.5.0/python-3.5.0-amd64.exe'
  installer_type :custom
  # https://docs.python.org/3.5/using/windows.html#installation-steps
  #
  # Install just for me. This installer is also smart enough to add to
  # the User Path under the just-for-me install. Yay!
  options '/passive InstallAllUsers=0 CompileAll=1 PrependPath=1 ' \
          'InstallLauncherAllUsers=0'
end

# Emacsen started through the shell will have the HOME variable set and be able
# to select the correct HOME. However, for Emacsen started through the GUI,
# HOME is unset. Set this registry key so Emacs finds the correct .emacs.d
# directory.
# https://www.gnu.org/software/emacs/manual/html_node/efaq-w32/Location-of-init-file.html
registry_key 'set Emacs HOME' do
  key 'HKEY_CURRENT_USER\SOFTWARE\GNU\Emacs'
  values [{ name: 'HOME', type: :string, data: node.windows_setup.home }]
  recursive true
end

# Create a desktop shortcut that runs Emacs through PowerShell. Because we are
# using Git from the GitHub for Windows application, and the path to this is
# defined within a PowerShell script, it's easiest to run Emacs from
# PowerShell. In this way, Emacs is run with all of our profile variables
# defined.
windows_shortcut 'create Emacs desktop shortcut' do
  name "#{node.windows_setup.desktop_dir}\\Emacs.lnk"
  target 'powershell'
  # Even with -WindowStyle Hidden, the command window shows up for a split
  # second. The other options are to wrap it in a C# or VbScript application,
  # which seems overkill for this. See:
  # http://stackoverflow.com/questions/1802127/how-to-run-a-powershell-script-without-displaying-a-window
  arguments '-NoLogo -NonInteractive -WindowStyle Hidden -Command emacs'
  description 'Run Emacs through PowerShell, loading my profile variables'
  iconlocation 'emacs.exe, 0'
end

# Emacs Cask
lambda do
  install_path = "#{node.windows_setup.home}\\.cask"
  git install_path do
    repository 'https://github.com/cask/cask.git'
    action :checkout
  end
  add_to_user_path "#{install_path}\\bin"
end.call

# Diablo II
#
# The game itself has a downloader and then an installer. The installer doesn't
# appear to be a garden-variety installer, so we'll just have to do this
# manually. NOTE: Install to our local apps dir, because otherwise Diablo II
# will need to run with Administrator privileges in order to connect to
# Battle.Net (or Slash Diablo).
#
# We need to modify the registry so Diablo II connects to the Slash Diablo
# server. These values are simplified because I don't need to connect to the
# official Diablo II servers, so we just overwrite them.
#
# https://www.reddit.com/r/slashdiablo/comments/lpgtw/slashdiablo_server_faq/
lambda do
  if is_package_installed?('Diablo II')
    registry_key 'set Diablo II Battle.Net gateways' do
      key 'HKEY_CURRENT_USER\Software\Battle.net\Configuration'
      values [{ name: 'Diablo II Battle.net gateways',
                type: :multi_string,
                data: [
                  # Fixed garbage
                  '1002',
                  '01',
                  # The order is IP, Zone, Name. The Zone is some type of
                  # priority, I guess.
                  node.windows_setup.diablo2.server,
                  '0',
                  'Slash Diablo',
                  'evnt.slashdiablo.net',
                  '1',
                  'Slash Diablo Event'
                ] }]
    end
    registry_key 'choose Diablo II Battle.Net gateway' do
      key node.windows_setup.diablo2.registry_key
      values [{ name: 'BNETIP', type: :string,
                data: node.windows_setup.diablo2.server }]
    end

    # Install the GLIDE wrapper; this allows the Steam overlay to work. The
    # files are available online, but I'm not sure how long it'll be there, so
    # I vendored it.
    #
    # Make sure to run D2VidTst.exe after installing to choose GLIDE as the
    # renderer. D2VidTst.exe usually needs to run in compatibility mode for
    # older Windows, so just be ready for that.
    install_path = registry_get_value(
      node.windows_setup.diablo2.registry_key, 'InstallPath')
    ['glide-init.exe', 'glide-readme.txt', 'glide3x.dll'].each do |file|
      cookbook_file "install GLIDE file #{file} to Diablo II directory" do
        source file
        path "#{install_path}\\#{file}"
      end
    end
  end
end.call

# Install NodeJS and tools
node.windows_setup.nodejs.tools.each do |tool|
  powershell_script "install Node.js tool #{tool}" do
    code "npm install --global '#{tool}'"
    not_if do
      JSON.parse(shell_out!('npm list --global --json').stdout)[
        'dependencies'].include? tool
    end
  end
end
