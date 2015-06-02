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

default['windows_setup']['home'] = ENV['USERPROFILE']
default['windows_setup']['scripts_dir'] =
  "#{default['windows_setup']['home']}\\bin"
default['windows_setup']['startup_dir'] =
  default['windows_setup']['home'] +
  '\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup'

default['windows_setup']['packages'] = %w(
  7zip
  ConEmu
  Firefox
  autohotkey
  carbon
  githubforwindows
  pscx
  scite4autohotkey
  sqlitebrowser
  sysinternals
  wixtoolset
)

default['windows_setup']['psget_modules'] = %w(
  PSReadLine
)
