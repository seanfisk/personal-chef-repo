# -*- coding: utf-8 -*-
#
# Author:: Sean Fisk <sean@seanfisk.com>
# Copyright:: Copyright (c) 2013, Sean Fisk
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

default['osx_setup']['home'] = ENV['HOME']
default['osx_setup']['personal_dir'] =
  "#{default['osx_setup']['home']}/src/personal"
default['osx_setup']['dotfiles_dir'] =
  "#{default['osx_setup']['personal_dir']}/dotfiles"
default['osx_setup']['emacs_dir'] =
  "#{default['osx_setup']['personal_dir']}/emacs"
default['osx_setup']['scripts_dir'] =
  "#{default['osx_setup']['home']}/bin"
default['osx_setup']['fonts_dir'] =
  "#{default['osx_setup']['home']}/Library/Fonts"
