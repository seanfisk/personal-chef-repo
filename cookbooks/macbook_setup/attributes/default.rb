# coding: UTF-8
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

default['macbook_setup']['home'] = ENV['HOME']
default['macbook_setup']['personal_dir'] =
  "#{default['macbook_setup']['home']}/src/personal"
default['macbook_setup']['dotfiles_dir'] =
  "#{default['macbook_setup']['personal_dir']}/dotfiles"
default['macbook_setup']['emacs_dir'] =
  "#{default['macbook_setup']['personal_dir']}/emacs"
default['macbook_setup']['scripts_dir'] =
  "#{default['macbook_setup']['home']}/bin"
default['macbook_setup']['packages'] = %w{
ack
coreutils
dos2unix
graphicsmagick
graphviz
htop
markdown
mobile-shell
parallel
rbenv
ruby-build
tmux
watch
wget
zsh
}
# aria2 # fails to build
# valgrind # fails to build
