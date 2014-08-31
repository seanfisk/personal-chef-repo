# -*- coding: utf-8 -*-
#
# Cookbook Name:: macosx_setup
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
require 'uri'
require 'mixlib/shellout'

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
  not_if { Etc.getpwuid.shell == PATH_TO_BASH }
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
  only_if { File.exist?('/etc/zshenv') }
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

# Deep Sleep Dashboard widget

# The original version (http://deepsleep.free.fr/) is unfortunately broken for
# newer Macs as the hibernate modes have changed. However, CODE2K has updated
# the widget for Mountain Lion (and Mavericks)
# (http://code2k.net/blog/2012-11-06/).

DEEP_SLEEP_ARCHIVE_NAME = 'deepsleep-1.3-beta1.zip'
DEEP_SLEEP_ARCHIVE_PATH =
  "#{Chef::Config[:file_cache_path]}/#{DEEP_SLEEP_ARCHIVE_NAME}"

remote_file 'download Deep Sleep dashboard widget' do
  source 'https://github.com/downloads/code2k/Deep-Sleep.wdgt/' +
         DEEP_SLEEP_ARCHIVE_NAME
  checksum 'fa41a926d7c1b6566b074579bdd4c9bc969d348292597ac3064731326efc4207'
  path DEEP_SLEEP_ARCHIVE_PATH
  notifies :run, 'execute[install Deep Sleep dashboard widget]'
end

execute 'install Deep Sleep dashboard widget' do
  command "unzip '#{DEEP_SLEEP_ARCHIVE_PATH}'"
  cwd "#{node['macosx_setup']['home']}/Library/Widgets"
  action :nothing
end

dmg_package 'Disk Inventory X' do
  source 'http://www.alice-dsl.net/tjark.derlien/DIX1.0Universal.dmg'
  checksum 'f61c070a1ec8f29ee78b8a7c84dd4124553098acc87134e2ef05dbaf2a442636'
  # Need to use this because the app name has spaces.
  dmg_name 'DiskInventoryX'
  action :install
end

# Eclipse
ECLIPSE_ARCHIVE_NAME = 'eclipse-standard-kepler-SR2-macosx-cocoa-x86_64.tar.gz'
ECLIPSE_ARCHIVE_PATH =
  "#{Chef::Config[:file_cache_path]}/#{ECLIPSE_ARCHIVE_NAME}"

remote_file 'download Eclipse' do
  source 'http://www.eclipse.org/downloads/download.php?file=/technology/' \
         "epp/downloads/release/kepler/SR2/#{ECLIPSE_ARCHIVE_NAME}&r=1"
  checksum '7fd761853ae7f5b280963059fcf8da6cea14c93563a3dfe7cc3491a7a977966e'
  path ECLIPSE_ARCHIVE_PATH
  notifies :run, 'execute[install Eclipse]'
end

execute 'install Eclipse' do
  command "tar -xf '#{ECLIPSE_ARCHIVE_PATH}'"
  # Put the 'eclipse' folder in /Applications. Doesn't make complete sense,
  # since the app bundle is inside this folder, but whatever. It should work
  # fine.
  cwd '/Applications'
  action :nothing
end

dmg_package 'Emacs' do
  # We are now using an unreleased build. There is a showstopping bug with
  # Emacs 24.3 on Mavericks which causes a memory leak in the 'distnoted'
  # process.
  #
  # - http://apple.stackexchange.com/questions/111197/runaway-distnoted-process
  # - https://gist.github.com/anonymous/8553178
  # - http://permalink.gmane.org/gmane.emacs.bugs/80836
  #
  # We will have to wait for 24.4 stable for this to be fixed.

  source 'http://emacsformacosx.com/emacs-builds/' \
         'Emacs-pretest-24.3.92-universal.dmg'
  checksum '0f6f7afc70b6cecc7644b15120461213127b968c6135bbe2091b13f864567e25'
  action :install
end

FIREFOX_VERSION = 26.0
dmg_package 'Firefox' do
  source 'http://download-installer.cdn.mozilla.net/pub/firefox/releases/' \
         "#{FIREFOX_VERSION}/mac/en-US/Firefox%20#{FIREFOX_VERSION}.dmg"
  checksum '0ea2b4cc1c56603d8449261ec2d97dba955056eb9029adfb85d002f6cd8a8952'
  action :install
end

# This is the Flash Player Projector (aka Flash Player "standalone"). It's
# useful for playing Flash games (in SWFs) on the desktop.
FLASH_PLAYER_VERSION = 13
dmg_package 'Flash Player' do
  source 'http://fpdownload.macromedia.com/pub/flashplayer/' \
         "updaters/#{FLASH_PLAYER_VERSION}/" \
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
backgrounds_dir = "#{node['macosx_setup']['home']}/Pictures/Backgrounds"
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
  path "#{node['macosx_setup']['home']}/Library/Preferences/" \
    'com.googlecode.iterm2.plist'
  variables(
    background_image_path: background_path,
    home_directory: node['macosx_setup']['home']
  )
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
# - Eclipse

# Note: Java 6 was installed, but uninstalled like so:
#
#     sudo rm -r /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
#     sudo pkgutil --forget com.apple.pkg.JavaForMacOSX107
#
# See here for the procedure followed: http://superuser.com/a/712783

# Java 7 JDK, from Oracle

# If you update, also be aware of the 'b13' in the URL below -- that will
# probably change.
JDK7_UPDATE_VERSION = 60
JDK7_VERSION = "7u#{JDK7_UPDATE_VERSION}"
JDK7_DMG_NAME = "jdk-#{JDK7_VERSION}-macosx-x64"
JDK7_PKG_AND_VOLUMES_DIR_NAME =
  "JDK 7 Update #{JDK7_UPDATE_VERSION}"

# rubocop:disable LineLength
# Oracle makes you agree to their agreement, which means some trickery is
# necessary. See here for more info:
# <http://stackoverflow.com/questions/10268583/how-to-automate-download-and-instalation-of-java-jdk-on-linux>
# rubocop:enable LineLength

pkgutil_proc = Mixlib::ShellOut.new(
  'pkgutil', '--pkg-info', 'com.oracle.jdk7u60')
pkgutil_proc.run_command
JDK7_IS_INSTALLED = pkgutil_proc.exitstatus == 0

remote_file 'download JDK 7 DMG' do
  # Note: JDK 7 is installed to
  # /Library/Java/JavaVirtualMachines/
  #
  # See here:
  # <http://docs.oracle.com/javase/7/docs/webnotes/install/mac/mac-jdk.html>

  source 'http://download.oracle.com/otn-pub/' \
    "java/jdk/#{JDK7_VERSION}-b19/#{JDK7_DMG_NAME}.dmg"
  path "#{Chef::Config[:file_cache_path]}/#{JDK7_DMG_NAME}.dmg"
  checksum 'a868aab818cd114f652252ded5b159b5c47beb1a0a074cdb0e475ed79826c9df'
  headers('Cookie' => 'oraclelicense=accept-securebackup-cookie')
  # A `notifies' attribute seems like a good idea here, but if it it's already
  # downloaded *but not installed*, there will be no notification. We'll just
  # hope it gets downloaded before the next provider runs.

  # Even if it's not in the cache, if we already have the JDK installed,
  # there's no reason to download it.
  not_if { JDK7_IS_INSTALLED }
end

# The name must not have spaces (requirement of dmg provider).
dmg_package 'Java7DevelopmentKit' do
  # Though this provider doesn't install an app bundle, the `app' attribute
  # specifies the name of the pkg file in the volume.
  app JDK7_PKG_AND_VOLUMES_DIR_NAME
  # A `source' attribute is not included. This causes the dmg provider to look
  # for the DMG specified by `dmg_name' in the Chef cache directory.
  type 'pkg'
  dmg_name JDK7_DMG_NAME
  volumes_dir JDK7_PKG_AND_VOLUMES_DIR_NAME
  action :install
  # We could use package_id here, but since that's pretty much what we do
  # above, we'll just stay consistent.
  not_if { JDK7_IS_INSTALLED }
end

KARABINER_VERSION = '10.2.0'
dmg_package 'Karabiner' do
  source 'https://pqrs.org/osx/karabiner/files/' \
         "Karabiner-#{KARABINER_VERSION}.dmg"
  checksum 'a5bd3717023d44a425f480289e13a66652bfe70f87c97bea03e73fded6283529'
  type 'pkg'
  package_id 'org.pqrs.driver.Karabiner'
  volumes_dir "Karabiner-#{KARABINER_VERSION}"
  action :install
end
# XML settings files
cookbook_file 'Karabiner XML settings file' do
  source 'Karabiner_private.xml'
  path "#{node['macosx_setup']['home']}/Library/Application Support/" \
       'Karabiner/private.xml'
end

# OSXFUSE and SSHFS

# Both of these pieces of software can be installed with Homebrew. However, it
# requires root and is therefore not automatic. I also don't believe that the
# Homebrew installer installs the OSXFUSE preferences pane.

# Note: The preference pane uninstaller does not appear to uninstall the
# preference pane itself.
OSXFUSE_MAJOR_VERSION = 2
OSXFUSE_MINOR_VERSION = 7
OSXFUSE_PATCH_VERSION = 0
OSXFUSE_FULL_VERSION =
  "#{OSXFUSE_MAJOR_VERSION}.#{OSXFUSE_MINOR_VERSION}.#{OSXFUSE_PATCH_VERSION}"
dmg_package 'OSXFUSE' do
  source 'http://downloads.sourceforge.net/project/osxfuse/' \
         "osxfuse-#{OSXFUSE_FULL_VERSION}/osxfuse-#{OSXFUSE_FULL_VERSION}.dmg"
  checksum 'fab4c8d16d0fc6995826d74f2c0ab04cd7264b00c566d5cc3b219bd589da8114'
  # Use the app keyword to override the name of the .pkg file.
  app "Install OSXFUSE #{OSXFUSE_MAJOR_VERSION}.#{OSXFUSE_MINOR_VERSION}"
  type 'pkg'
  package_id 'com.github.osxfuse.pkg.Core'
  volumes_dir 'FUSE for OS X'
  action :install
end

SSHFS_VERSION = '2.5.0'
pkgutil_proc = Mixlib::ShellOut.new(
  'pkgutil', '--pkg-info', 'com.github.osxfuse.pkg.SSHFS')
pkgutil_proc.run_command
SSHFS_IS_INSTALLED = pkgutil_proc.exitstatus == 0
SSHFS_PKG_PATH = "#{Chef::Config[:file_cache_path]}/sshfs.pkg"

remote_file 'download SSHFS pkg' do
  source 'https://github.com/osxfuse/sshfs/releases/download/' \
         "osxfuse-sshfs-#{SSHFS_VERSION}/sshfs-#{SSHFS_VERSION}.pkg"
  path SSHFS_PKG_PATH
  checksum 'f8f4f71814273ea42dbe6cd92199f7cff418571ffd1b10c0608878d3472d2162'
  # A `notifies' attribute seems like a good idea here, but if it it's already
  # downloaded *but not installed*, there will be no notification. We'll just
  # hope it gets downloaded before the next provider runs.

  # Even if it's not in the cache, if we already have it installed, there's no
  # reason to download it.
  not_if { SSHFS_IS_INSTALLED }
end

execute 'run SSHFS package installer' do
  command "sudo installer -pkg '#{SSHFS_PKG_PATH}' -target /"
  not_if { SSHFS_IS_INSTALLED }
end

QUICKSILVER_VERSION = '1.0.0'
dmg_package 'Quicksilver' do
  source 'http://github.qsapp.com/downloads/' \
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
    File.exist?(node['macosx_setup']['home'] +
                 "/Library/Preferences/#{source}")
  end
end

dmg_package 'Skim' do
  source 'http://downloads.sourceforge.net/project/' \
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
  path "#{node['macosx_setup']['home']}/.slate"
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
  source "http://download.virtualbox.org/virtualbox/#{VIRTUALBOX_VERSION}/" \
         "VirtualBox-#{VIRTUALBOX_VERSION}-93012-OSX.dmg"
  checksum '8bf24a7afbde0cdb560b40abd8ab69584621ca6de59026553f007a0da7b4d443'
  type 'pkg'
  package_id 'org.virtualbox.pkg.virtualbox'
  action :install
end

# Wireshark initially used GTK+ as the GUI library, but is switching to Qt.
# According to their blog post announcement:
#
#     If you're running OS X you should use the Qt flavor. For common tasks it
#     should have a better workflow. Again, if it doesn't we aren't doing our
#     job.
#
# Source: https://blog.wireshark.org/2013/10/switching-to-qt/
#
# The newest release (1.12.0) still includes the GTK+ version in the Mac DMG.
# However, the 'Capture Filters...' and 'Display Filters...' dialogs are
# broken. These are pretty important, so we've decided to stick with GTK+ and
# X11 for now. Here is the Qt version that we tried.
#
# Run with 'wireshark-qt' on the command-line (unfortunately, it's not an app
# bundle).
# package 'wireshark' do
#   options '--with-qt --devel'
#   action :install
# end

# Here the GTK+ DMG code until Wireshark switches their official Mac releases
# to Qt.

WIRESHARK_VERSION = '1.12.0'
WIRESHARK_FULL_NAME = "Wireshark #{WIRESHARK_VERSION} Intel 64"
dmg_package 'Wireshark' do
  # The Wireshark DMG also includes instructions on how to uninstall, which is
  # great.

  # Use the app keyword to override the name of the .pkg file, which includes
  # the version and architecture.
  app WIRESHARK_FULL_NAME

  # But then we need to override the volume dir and dmg name, which are based
  # on the app name. The dmg name can't have spaces, and the volumes dir has to
  # be, well, correct.
  dmg_name 'Wireshark'
  volumes_dir 'Wireshark'

  # Don't forget to escape the spaces (into '%20').
  source 'http://wiresharkdownloads.riverbed.com/wireshark/osx/' +
         URI.escape(WIRESHARK_FULL_NAME) + '.dmg'
  checksum '2e4131fe32b72339cb8d8191e591711c16f4c5950657428810fdfce91b0dead2'
  type 'pkg'
  package_id 'org.wireshark.Wireshark.pkg'
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

directory node['macosx_setup']['personal_dir'] do
  recursive true
  action :create
end

git node['macosx_setup']['dotfiles_dir'] do
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
  cwd node['macosx_setup']['dotfiles_dir']
  action :nothing
end

git node['macosx_setup']['emacs_dir'] do
  repository 'git@github.com:seanfisk/emacs.git'
  enable_submodules true
  action :checkout
  notifies :run, 'execute[install emacs configuration]'
end

execute 'install emacs configuration' do
  command 'make install'
  cwd node['macosx_setup']['emacs_dir']
  action :nothing
end

# Install tmux-MacOSX-pasteboard reattach-to-user-namespace program
directory node['macosx_setup']['scripts_dir'] do
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
    '#{node['macosx_setup']['scripts_dir']}'
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

node['macosx_setup']['packages'].each do |pkg_name|
  package pkg_name do
    action :install
  end
end

# Install fonts.

## Ubuntu
UBUNTU_FONT_ARCHIVE_NAME = 'ubuntu-font-family-0.80.zip'
UBUNTU_FONT_ARCHIVE_PATH =
  "#{Chef::Config[:file_cache_path]}/#{UBUNTU_FONT_ARCHIVE_NAME}"
UBUNTU_FONT_DIR = "#{node['macosx_setup']['fonts_dir']}/Ubuntu"

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
  path "#{node['macosx_setup']['fonts_dir']}/#{INCONSOLATA_FILE}"
  action :create_if_missing
end

## Inconsolata for Powerline
INCONSOLATA_POWERLINE_FILE = 'Inconsolata for Powerline.otf'
remote_file 'download Inconsolata for Powerline font' do
  source 'https://github.com/Lokaltog/powerline-fonts/raw/'\
         'master/Inconsolata/' + URI.escape(INCONSOLATA_POWERLINE_FILE)
  path "#{node['macosx_setup']['fonts_dir']}/#{INCONSOLATA_POWERLINE_FILE}"
  action :create_if_missing
end
