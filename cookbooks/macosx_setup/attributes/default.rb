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
# - Dos2Unix / Unix2Dos <http://waterlan.home.xs4all.nl/dos2unix.html> looks
#   superior to Tofrodos <http://www.thefreecountry.com/tofrodos/>. But that
#   was just from a quick look.
# - ZeroMQ (zmq) is included to speed up IPython installs. It can install a
#   bundled version to a virtualenv, but it's faster to have a globally built
#   version.
# - Install both GraphicMagick and ImageMagick. In generally, I prefer
#   GraphicsMagick, but ImageMagick has ICO support so we use it for
#   BetterPlanner.
# - ImageMagick might already be present on the system (but just 'convert').
#   I'm not sure if it's just an artifact of an earlier build, but it was on my
#   Mavericks system before I installed it (again?).
# - libgit2 is for pygit2 for Powerline.
# - zpython is also for Powerline.
# - texinfo is mainly for Sphinx.
# - pwgen and sf-pwgen are both password generators. pwgen is more generic,
#   whereas sf-pwgen uses Apple's security framework. We also looked at APG,
#   but it seems unmaintained.
# - reattach-to-user-namespace has options to fix launchctl and shim
#   pbcopy/pbaste. We haven't needed them yet, though.
#
default['macosx_setup']['packages'] = %w(
  ack
  aria2
  astyle
  coreutils
  dos2unix
  doxygen
  editorconfig
  fasd
  git
  gnu-tar
  graphicsmagick
  graphviz
  htop-osx
  hub
  imagemagick
  libgit2
  markdown
  mercurial
  mobile-shell
  nmap
  node
  ohcount
  p7zip
  parallel
  pstree
  pwgen
  pyenv
  pyenv-virtualenv
  pyenv-which-ext
  qpdf
  rbenv
  reattach-to-user-namespace
  ruby-build
  sf-pwgen
  ssh-copy-id
  texinfo
  the_silver_searcher
  tmux
  tree
  valgrind
  watch
  wget
  xz
  zmq
  zpython
  zsh
)
