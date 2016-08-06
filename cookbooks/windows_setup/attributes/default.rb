# -*- coding: utf-8 -*-
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

default['windows_setup'].tap do |w|
  # Arguments used to run a batch PowerShell command
  w['ps_args'] = 'powershell -NoLogo -NonInteractive -NoProfile -Command'

  w['home'] = ENV['USERPROFILE']
  w['scripts_dir'] = "#{w['home']}\\bin"
  w['apps_dir'] = "#{w['home']}\\Applications"

  # Inspired by:
  # - https://github.com/opscode-cookbooks/windows#examples-12
  # - https://msdn.microsoft.com/en-us/library/0ea7b5xe%28v=vs.84%29.aspx
  require 'win32ole'
  wshell = WIN32OLE.new('WScript.Shell')

  w['startup_dir'] = wshell.SpecialFolders('Startup')
  w['desktop_dir'] = wshell.SpecialFolders('Desktop')

  w['explorer_registry_key'] =
    'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer'
  w['time_zone'] = 'Eastern Standard Time'

  w['packages'] = [
    '7zip',
    'ConEmu',
    'Firefox',
    'autohotkey',
    'carbon',
    # On OS X and GNU/Linux, we don't use the ChefDK. But it makes installation
    # of a development environment very easy on Windows.
    'chefdk',
    'dependencywalker',
    'flashplayerplugin',
    'gimp',
    'githubforwindows',
    'nodejs',
    'pscx',
    'scite4autohotkey',
    'sqlitebrowser',
    'steam',
    'switcheroo',
    'sysinternals',
    'wixtoolset'
  ]

  w['chocolatey']['features'] = %w(
    checksumFiles
    autoUninstaller
    allowGlobalConfirmation
    failOnAutoUninstaller
  )

  w['psget']['modules'] = %w(
    PSReadLine
  )

  w['nodejs']['tools'] = %w(
    jsonlint
    uglify-js
  )

  w['diablo2'] = {
    registry_key: 'HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo II',
    server: 'play.slashdiablo.net'
  }
end
