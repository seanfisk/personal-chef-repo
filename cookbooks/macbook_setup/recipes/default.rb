# -*- coding: utf-8 -*-
#
# Cookbook Name:: macbook_setup
# Recipe:: default
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

require 'etc'

# Include homebrew as the default package manager.
# (default is MacPorts)
include_recipe 'homebrew'

# Set latest bash 4 as the default shell.
#
# Unfortunately, these commands will cause password prompts, meaning
# chef has to be watched. The "workaround" is to put them at the
# beginning of the run.
#
# We also need to install bash separately from the other homebrew
# packages because it needs to be available for changing the default
# shell. We don't want to wait for all the other packages to be
# installed to see the prompt, but we need the shell to be available
# before setting it as the default.
package 'bash' do
  action :install
end

PATH_TO_BASH = '/usr/local/bin/bash'
SHELLS_FILE = '/etc/shells'

# First, add bash to /etc/shells so it is recognized as a valid user shell.
execute "add latest bash to #{SHELLS_FILE}" do
  # Unfortunately, this cannot be a ruby_block as that would prevent it from
  # running with sudo. See the mactex cookbook for more information.
  command "sudo bash -c 'echo #{PATH_TO_BASH} >> #{SHELLS_FILE}'"
  not_if do
    # Don't execute if this bash is already in the shells config file.
    File.open(SHELLS_FILE).lines.any? do
      |line| line.include?(PATH_TO_BASH)
    end
  end
end

# Then, set bash as the current user's shell.
execute 'set latest bash as default shell' do
  command "chsh -s '#{PATH_TO_BASH}'"
  # getpwuid defaults to the current user, which is what we want.
  not_if { Etc.getpwuid().shell == PATH_TO_BASH }
end

# Make sure to use the `execute' resource than the `bash' resource, otherwise
# sudo cannot prompt for a password.
execute 'fix the zsh startup file that path_helper uses' do
  # Mac OS X has a program called path_helper that allows paths to be easily
  # set for multiple shells. For bash (and other shells), it works great
  # because it is called /etc/profile which is executed only for login shells.
  # However, with zsh, path_helper is run from /etc/zshenv *instead of*
  # /etc/zprofile like it should be. This fixes Apple's mistake.
  #
  # See this link for more information:
  # <https://github.com/sorin-ionescu/prezto/issues/381>
  command 'sudo mv /etc/zshenv /etc/zprofile'
  only_if { File.exists?('/etc/zshenv') }
end

include_recipe 'dmg'
include_recipe 'zip'
include_recipe 'mac_os_x'

# Password-protected screensaver + delay
include_recipe 'mac_os_x::screensaver'

# Turn on the OS X firewall.
include_recipe 'mac_os_x::firewall'

# Set up fast key repeat with low initial delay.
include_recipe 'mac_os_x::key_repeat'

# Set up clock with day of week, date, and 24-hour clock.
mac_os_x_plist_file 'com.apple.menuextra.clock.plist'

# Show percentage on battery indicator.
mac_os_x_plist_file 'com.apple.menuextra.battery.plist'

ADIUM_VERSION = '1.5.6'
dmg_package 'Adium' do
  source "http://download.adium.im/Adium_#{ADIUM_VERSION}.dmg"
  checksum 'd5f580b7db57348c31f8e0f18691d7758a65ad61471bf984955360f91b21edb8'
  volumes_dir "Adium #{ADIUM_VERSION}"
  action :install
end

dmg_package 'Chicken' do
  source 'http://sourceforge.net/projects/chicken/files/Chicken-2.2b2.dmg'
  checksum '20e910b6cbf95c3e5dcf6fe8e120d5a0911f19099128981fb95119cee8d5fc6b'
  action :install
end

zip_package 'Dash' do
  source 'http://dallas.kapeli.com/Dash.zip'
  checksum '76388ef51832885f87b4059fc4ec34c74d71b8b80d55a2a86796eaf1673bf4e8'
  action :install
end

dmg_package 'Disk Inventory X' do
  source 'http://www.alice-dsl.net/tjark.derlien/DIX1.0Universal.dmg'
  checksum 'f61c070a1ec8f29ee78b8a7c84dd4124553098acc87134e2ef05dbaf2a442636'
  # Need to use this because the app name has spaces.
  dmg_name 'DiskInventoryX'
  action :install
end

dmg_package 'Emacs' do
  # We are now using a nightly build. There is a showstopping bug with Emacs
  # 24.3 on Mavericks which causes a memory leak in the 'distnoted' process.
  # See:
  # - http://apple.stackexchange.com/questions/111197/runaway-distnoted-process
  # - https://gist.github.com/anonymous/8553178
  # - http://permalink.gmane.org/gmane.emacs.bugs/80836
  #
  # We will have to wait for 24.4 stable for this to be fixed.
  source 'http://emacsformacosx.com/emacs-builds/' +
         # 'Emacs-24.3-universal-10.6.8.dmg'
         'Emacs-2014-02-14_01-34-10-116442-universal-10.6.8.dmg'
  # checksum '92b3a6dd0a32b432f45ea925cfa34834c9ac9f7f0384c38775f6760f1e89365a'
  checksum '6dc23cd554175c8023e6aabd00f132df4e687d552a7b960a73b880693e96d6b6'
  action :install
end

FIREFOX_VERSION = 26.0
dmg_package 'Firefox' do
  source 'http://download-installer.cdn.mozilla.net/pub/firefox/releases/' +
         "#{FIREFOX_VERSION}/mac/en-US/Firefox%20#{FIREFOX_VERSION}.dmg"
  checksum '0ea2b4cc1c56603d8449261ec2d97dba955056eb9029adfb85d002f6cd8a8952'
  action :install
end

# This is the Flash Player Projector (aka Flash Player "standalone"). It's
# useful for playing Flash games (in SWFs) on the desktop.
FLASH_PLAYER_VERSION = 13
dmg_package 'Flash Player' do
  source 'http://fpdownload.macromedia.com/pub/flashplayer/' +
         "updaters/#{FLASH_PLAYER_VERSION}/" +
         "flashplayer_#{FLASH_PLAYER_VERSION}_sa.dmg"
  checksum 'eeb47ba093876fc25d4993e0f7652e398c66c9f0a0e89d01586ab33c7a82bab2'
  action :install
end

zip_package 'Flux' do
  source 'https://justgetflux.com/mac/Flux.zip'
  checksum '7cc07a4865b45f6e9b4736b5eb25db21e16bbcd36ce447fee54394ccb9a0d360'
  action :install
end

zip_package 'gfxCardStatus' do
  source 'http://gfx.io/downloads/gfxCardStatus-2.3.zip'
  checksum '092b3e2fad44681ba396cf498707c8b6c228fd55310770a8323ebb9344b4d9a1'
  action :install
end
# Install the gfxCardStatus preferences. This WILL overwrite current setting
# (there are barely any :).
mac_os_x_plist_file 'com.codykrieger.gfxCardStatus-Preferences.plist'

dmg_package 'GIMP' do
  source 'http://ftp.gimp.org/pub/gimp/v2.8/osx/gimp-2.8.10-dmg-1.dmg'
  checksum 'e93a84cd5eff4fe1c987c9c358f9de5c3532ee516bce3cd5206c073048cddba5'
  action :install
end

dmg_package 'Google Chrome' do
  source 'https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
  checksum 'ba4d6fe46e5b8deef5cfe5691e2c36ac3eb15396fefeb6d708c7c426818e2f11'
  # Need to use this because the app name has spaces.
  dmg_name 'GoogleChrome'
  action :install
end

# iTerm2
## Install iTerm2 background image.
backgrounds_dir = "#{node['macbook_setup']['home']}/Pictures/Backgrounds"
background_name = 'holland-beach-sunset.jpg'
background_path = "#{backgrounds_dir}/#{background_name}"

directory backgrounds_dir
cookbook_file background_name do
  path background_path
end

## Install plist, containing lots of themes, configuration, and
## background image setup.
template 'iTerm2 preferences file' do
  source 'com.googlecode.iterm2.plist.erb'
  path "#{node['macbook_setup']['home']}/Library/Preferences/" +
    'com.googlecode.iterm2.plist'
  variables({
              background_image_path: background_path,
              home_directory: node['macbook_setup']['home']
   })
end

## Include the iTerm2 recipe. This must be called AFTER the plist
## command above for the following reason: The iterm2 cookbook can
## also install the iTerm2 plist from files/default. We can't use
## this, however, because we include the iterm2 cookbook through
## Berkshelf, meaning that we can't write to that cookbook. The iterm2
## cookbook declares a mac_os_x_plist_file just like ours, but it
## fails because that file doesn't exist in the iterm2 cookbook.
## ignore_failure is set to true, so it continues. If we make our call
## after including the iterm2 cookbook, Chef remembers the config from
## the first call to mac_os_x_plist_file and fails once again.
##
## This might not be a problem since we are now using a template above.
include_recipe 'iterm2'

# Java
# I wish we could avoid installing Java, but I need it for at least these
# reasons:
#
# - Network Connect, GVSU's SSL VPN
# - Playing TankPit, a Java applet-based game
#
# GVSU's Network Connect, as of 2013-01-24, needs Java 6. Argh.

# Java 6 JDK, from Apple

# Thanks for the naming consistency, Apple! [sarcasm] Apparently the goal was
# to format the name in as many different ways as possible.
#
# Apple distributes the JDK, it's not possible (or plausible, I guess) to get
# the JRE.
#
# rubocop:disable LineLength
#
# To see all files install by *this* installer, run:
#
#     pkgutil --bom '/Volumes/Java for OS X 2013-005/JavaForOSX.pkg' | while read -r bom_path; do lsbom -lfs "$bom_path"; done
#
# Note: Java 6 is installed to /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
#
# rubocop:enable LineLength

JDK6_DMG_NAME = 'JavaForOSX2013-05'

# The name must not have spaces (requirement of dmg provider).
dmg_package 'Java6DevelopmentKit' do
  source 'http://support.apple.com/downloads/' +
    "DL1572/en_US/#{JDK6_DMG_NAME}.dmg"
  checksum '81e1155e44b2c606db78487ca1a02e31dbb3cfbf7e0581a4de3ded9e635a704e'
  # Though this provider doesn't install an app bundle, the `app' attribute
  # specifies the name of the pkg file in the volume.
  app 'JavaForOSX'
  type 'pkg'
  dmg_name JDK6_DMG_NAME
  volumes_dir 'Java for OS X 2013-005'
  action :install
  package_id 'com.apple.pkg.JavaForMacOSX107'
end

# Java 7 JRE, from Oracle

# If you update, also be aware of the 'b13' in the URL below -- that will
# probably change.
JRE7_UPDATE_VERSION = 51
JRE7_VERSION = "7u#{JRE7_UPDATE_VERSION}"
JRE7_DMG_NAME = "jre-#{JRE7_VERSION}-macosx-x64"
JRE7_PKG_AND_VOLUMES_DIR_NAME =
  "Java 7 Update #{JRE7_UPDATE_VERSION}"

# Oracle makes you agree to their agreement, which means some trickery is
# necessary. See here for more info:
# <http://stackoverflow.com/questions/10268583/how-to-automate-download-and-instalation-of-java-jdk-on-linux> # rubocop:disable LineLength

require 'uri'

JRE7_IS_INSTALLED = system('pkgutil --pkgs=com.oracle.jre')

remote_file 'download Java 7 runtime environment DMG' do
  # Note: Java 7 is installed to
  # /Library/Internet Plug-Ins/JavaAppletPlugin.plugin
  #
  # See here:
  # <http://docs.oracle.com/javase/7/docs/webnotes/install/mac/mac-jre.html>
  source 'http://download.oracle.com/otn-pub/' +
    "java/jdk/#{JRE7_VERSION}-b13/#{JRE7_DMG_NAME}.dmg?"
  path "#{Chef::Config[:file_cache_path]}/#{JRE7_DMG_NAME}.dmg"
  checksum '8541090bf8bd7b284f07d4b1f74b5352b8addf5e0274eeb82cacdc4b2e2b66d2'
  headers('Cookie' =>
          URI.encode_www_form('gpw_e24' => 'http://www.oracle.com'))
  # A `notifies' attribute seems like a good idea here, but if it it's already
  # downloaded *but not installed*, there will be no notification. We'll just
  # hope it gets downloaded before the next provider runs.

  # Even if it's not in the cache, if we already have the JRE installed,
  # there's no reason to download it.
  not_if { JRE7_IS_INSTALLED }
end

# The name must not have spaces (requirement of dmg provider).
dmg_package 'Java7RuntimeEnvironment' do
  # Though this provider doesn't install an app bundle, the `app' attribute
  # specifies the name of the pkg file in the volume.
  app JRE7_PKG_AND_VOLUMES_DIR_NAME
  # A `source' attribute is not included. This causes the dmg provider to look
  # for the DMG specified by `dmg_name' in the Chef cache directory.
  type 'pkg'
  dmg_name JRE7_DMG_NAME
  volumes_dir JRE7_PKG_AND_VOLUMES_DIR_NAME
  action :install
  # We could use package_id here, but since that's pretty much what we do
  # above, we'll just stay consistent.
  not_if { JRE7_IS_INSTALLED }
end

QUICKSILVER_VERSION = '1.0.0'
dmg_package 'Quicksilver' do
  source 'http://github.qsapp.com/downloads/' +
    "Quicksilver%20#{QUICKSILVER_VERSION}.dmg"
  checksum '0afb16445d12d7dd641aa8b2694056e319d23f785910a8c7c7de56219db6853c'
  action :install
  # This should work but it doesn't seem to. So we went with the
  # `not_if' solution below.
  # notifies :create, 'mac_os_x_plist_file[com.blacktree.Quicksilver.plist]'
end

mac_os_x_plist_file 'com.blacktree.Quicksilver.plist' do
  # Create a plist file for Quicksilver specifying the hotkey, among
  # other things. Unfortunately, this doesn't avoid going through the
  # setup assistant, but it helps out a bit.

  # Don't overwrite the file if it already exists.
  not_if do
    File.exists?(node['macbook_setup']['home'] +
                 "/Library/Preferences/#{source}")
  end
end

dmg_package 'Skim' do
  source 'http://downloads.sourceforge.net/project/' +
    'skim-app/Skim/Skim-1.4.7/Skim-1.4.7.dmg'
  checksum 'c8789c23cf66359adca5f636943dce3b440345da33ae3b5fa306ac2d438a968e'
  action :install
end

dmg_package 'Slate' do
  source 'http://slate.ninjamonkeysoftware.com/Slate.dmg'
  checksum '428e375d5b1c64f79f1536acb309e4414c3178051c6fe0b2f01a94a0803e223f'
  action :install
end
# TODO: Consider using JavaScript preferences (replacing .slate, or to
# supplement it).
cookbook_file 'Slate preferences file' do
  source 'slate'
  path "#{node['macbook_setup']['home']}/.slate"
end

# FYI: Vagrant has an uninstaller with its DMG! Just so you know.
dmg_package 'Vagrant' do
  source 'https://dl.bintray.com/mitchellh/vagrant/vagrant_1.6.0.dmg'
  checksum '6d6a77a9180f79a1ac69053c28a7cb601b60fe033344881281bab80cde04bf71'
  type 'pkg'
  package_id 'com.vagrant.vagrant'
  action :install
end

# If you update, be aware that the number following the version in the URL will
# also probably change.
VIRTUALBOX_VERSION = '4.3.10'
dmg_package 'VirtualBox' do
  source "http://download.virtualbox.org/virtualbox/#{VIRTUALBOX_VERSION}/" +
         "VirtualBox-#{VIRTUALBOX_VERSION}-93012-OSX.dmg"
  checksum '8bf24a7afbde0cdb560b40abd8ab69584621ca6de59026553f007a0da7b4d443'
  type 'pkg'
  package_id 'org.virtualbox.pkg.virtualbox'
  action :install
end

dmg_package 'XQuartz' do
  # Note: XQuartz is installed to /Applications/Utilities/XQuartz.app
  source 'http://xquartz.macosforge.org/downloads/SL/XQuartz-2.7.5.dmg'
  checksum '4382ff78cef5630fb6b8cc982da2e5a577d8cc5dddd35a493b50bad2fcf5e34a'
  type 'pkg'
  volumes_dir 'XQuartz-2.7.5'
  package_id 'org.macosforge.xquartz.pkg'
  action :install
end

# Clone my dotfiles and emacs git repositories

directory node['macbook_setup']['personal_dir'] do
  recursive true
  action :create
end

git node['macbook_setup']['dotfiles_dir'] do
  repository 'git@github.com:seanfisk/dotfiles.git'
  enable_submodules true
  action :checkout
  notifies :run, 'execute[install dotfiles]'
end

execute 'install dotfiles' do
  # Running `make install-osx' does the regular install, then patches
  # .tmux.conf to make this work:
  # <https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard>
  command 'make install-osx'
  cwd node['macbook_setup']['dotfiles_dir']
  action :nothing
end

git node['macbook_setup']['emacs_dir'] do
  repository 'git@github.com:seanfisk/emacs.git'
  enable_submodules true
  action :checkout
  notifies :run, 'execute[install emacs configuration]'
end

execute 'install emacs configuration' do
  command 'make install'
  cwd node['macbook_setup']['emacs_dir']
  action :nothing
end

# Install tmux-MacOSX-pasteboard reattach-to-user-namespace program
directory node['macbook_setup']['scripts_dir'] do
  recursive true
  action :create
end

tmux_macosx_dir =
  "#{Chef::Config[:file_cache_path]}/tmux-MacOSX-pasteboard"
git tmux_macosx_dir do
  repository 'https://github.com/ChrisJohnsen/tmux-MacOSX-pasteboard.git'
  action :sync
  notifies :run, 'bash[compile and install tmux-MacOSX-pasteboard]'
end

bash 'compile and install tmux-MacOSX-pasteboard' do
  # We are using a line continuation in a Bash script, not in Ruby.
  # rubocop:disable LineContinuation
  code <<-EOH
  set -o errexit # exit on first error
  make reattach-to-user-namespace
  cp reattach-to-user-namespace \\
    '#{node["macbook_setup"]["scripts_dir"]}'
  EOH
  # rubocop:enable LineContinuation
  cwd tmux_macosx_dir
  action :nothing
end

# About installing rbenv
#
# Even though the rbenv cookbooks looks nice, they don't work as I'd
# like. fnichol's supports local install, but insists on templating
# /etc/profile.d/rbenv.sh *even when doing a local install*. That
# makes no sense. I don't want that.
#
# The RiotGames rbenv cookbook only supports global install.
#
# So let's just install through trusty Homebrew.
#
# We now also install pyenv through Homebrew, so it's nice to be consistent.

# Install Homebrew packages

node['macbook_setup']['packages'].each do |pkg_name|
  package pkg_name do
    action :install
  end
end

# Install fonts.

## Ubuntu
UBUNTU_FONT_ARCHIVE_NAME = 'ubuntu-font-family-0.80.zip'
UBUNTU_FONT_ARCHIVE_PATH =
  "#{Chef::Config[:file_cache_path]}/#{UBUNTU_FONT_ARCHIVE_NAME}"
UBUNTU_FONT_DIR = "#{node['macbook_setup']['fonts_dir']}/Ubuntu"

directory UBUNTU_FONT_DIR

remote_file 'download Ubuntu fonts' do
  source "http://font.ubuntu.com/download/#{UBUNTU_FONT_ARCHIVE_NAME}"
  # This font release's checksum is unlikely to change.
  checksum '107170099bbc3beae8602b97a5c423525d363106c3c24f787d43e09811298e4c'
  path UBUNTU_FONT_ARCHIVE_PATH
  notifies :run, 'execute[install Ubuntu fonts]'
end

execute 'install Ubuntu fonts' do
  command "unzip '#{UBUNTU_FONT_ARCHIVE_PATH}'"
  cwd UBUNTU_FONT_DIR
  action :nothing
end

## Inconsolata
INCONSOLATA_FILE = 'Inconsolata.otf'
remote_file 'download Inconsolata font' do
  # This URL seems like one that may be updated with newer versions, so we'll
  # just install the current version if it's not already installed.
  source "http://levien.com/type/myfonts/#{INCONSOLATA_FILE}"
  path "#{node['macbook_setup']['fonts_dir']}/#{INCONSOLATA_FILE}"
  action :create_if_missing
end
