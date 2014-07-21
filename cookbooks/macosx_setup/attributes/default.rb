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

default['macosx_setup']['home'] = ENV['HOME']
default['macosx_setup']['personal_dir'] =
  "#{default['macosx_setup']['home']}/src/personal"
default['macosx_setup']['dotfiles_dir'] =
  "#{default['macosx_setup']['personal_dir']}/dotfiles"
default['macosx_setup']['emacs_dir'] =
  "#{default['macosx_setup']['personal_dir']}/emacs"
default['macosx_setup']['scripts_dir'] =
  "#{default['macosx_setup']['home']}/bin"
default['macosx_setup']['fonts_dir'] =
  "#{default['macosx_setup']['home']}/Library/Fonts"

# Notes:
#
# - To fix the aria2 build, I ran `brew edit gmp' and added a
#   `--with-pic' flag. Hopefully I will not have issues in the
#   future. See here: <https://github.com/mxcl/homebrew/issues/12946>
# - I prefer ohcount to cloc and sloccount.
# - ZeroMQ (zmq) is included to speed up IPython installs. It can install a
#   bundled version to a virtualenv, but it's faster to have a globally built
#   version.
# - Install both GraphicMagick and ImageMagick. In generally, I prefer
#   GraphicsMagick, but ImageMagick has ICO support so we use it for
#   BetterPlanner.
# - ImageMagick might already be present on the system (but just 'convert').
#   I'm not sure if it's just an artifact of an earlier build, but it was on my
#   Mavericks system before I installed it (again?).
#
default['macosx_setup']['packages'] = %w(
  ack
  ag
  aria2
  astyle
  autojump
  coreutils
  dos2unix
  doxygen
  editorconfig
  git
  graphicsmagick
  graphviz
  htop
  imagemagick
  markdown
  mobile-shell
  nmap
  node
  ohcount
  parallel
  pstree
  pyenv
  pyenv-virtualenv
  pyenv-which-ext
  qpdf
  rbenv
  ruby-build
  ssh-copy-id
  tmux
  tree
  valgrind
  watch
  wget
  zmq
  zsh
)
