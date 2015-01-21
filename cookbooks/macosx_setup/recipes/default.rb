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

# Include homebrew as the default package manager (default is MacPorts).
include_recipe 'homebrew'

brew_proc = Mixlib::ShellOut.new('brew', '--prefix')
brew_proc.run_command
BREW_PREFIX = brew_proc.stdout.rstrip

# Add the latest bash and zsh as possible login shells.
#
# Unfortunately, these commands will cause password prompts, meaning
# chef has to be watched. The "workaround" is to put them at the
# beginning of the run.
#
# We also need to install the shells separately from the other Homebrew
# packages because it needs to be available for changing the default shell. We
# don't want to wait for all the other packages to be installed to see the
# prompt, but we need the shell to be available before setting it as the
# default.
SHELLS_FILE = '/etc/shells'
shells_file_lines = File.open(SHELLS_FILE).lines
%w(bash zsh).each do |shell|
  # Install the shell using Homebrew.
  package shell do
    action :install
  end

  shell_path = File.join(BREW_PREFIX, 'bin', shell)
  # First, add shell to /etc/shells so it is recognized as a valid user shell.
  execute "add #{shell_path} to #{SHELLS_FILE}" do
    # Unfortunately, this cannot be a ruby_block as that would prevent it from
    # running with sudo. See the mactex cookbook for more information.
    command "sudo bash -c \"echo '#{shell_path}' >> '#{SHELLS_FILE}'\""
    not_if do
      # Don't execute if this shell is already in the shells config file.
      shells_file_lines.any? do
        |line| line.include?(shell_path)
      end
    end
  end
end

# Then, set zsh as the current user's shell.
ZSH_PATH = File.join(BREW_PREFIX, 'bin', 'zsh')
execute "set #{ZSH_PATH} as default shell" do
  command "chsh -s '#{ZSH_PATH}'"
  # getpwuid defaults to the current user, which is what we want.
  not_if { Etc.getpwuid.shell == ZSH_PATH }
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

# This isn't perfect -- the widget will only download and install when the
# archive file doesn't exist.
remote_file 'download Deep Sleep dashboard widget' do
  source 'https://github.com/downloads/code2k/Deep-Sleep.wdgt/' +
         DEEP_SLEEP_ARCHIVE_NAME
  checksum 'fa41a926d7c1b6566b074579bdd4c9bc969d348292597ac3064731326efc4207'
  path DEEP_SLEEP_ARCHIVE_PATH
  notifies :run, 'execute[install Deep Sleep dashboard widget]'
end

execute 'install Deep Sleep dashboard widget' do
  command "unzip -o '#{DEEP_SLEEP_ARCHIVE_PATH}'"
  cwd "#{node['macosx_setup']['home']}/Library/Widgets"
  action :nothing
end

# devpi caching PyPi server
# DEVPI_PLIST_NAME = 'net.devpi.plist'
# cookbook_file 'devpi Launch Agent' do
#   source DEVPI_PLIST_NAME
#   path "#{node['macosx_setup']['home']}/Library/LaunchAgents/" +
#        DEVPI_PLIST_NAME
#   # Override the umask and set the mode. The file must be writable *only by
#   # the user* otherwise launchd will not load it. Be conservative and zero
#   # the group and other permissions.
#   mode '0600'
# end

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
  source 'http://emacsforosx.com/emacs-builds/Emacs-24.4-universal.dmg'
  checksum '2d13ff9edff16d4e8f4bc9cf37961cf91a3f308fad5e9c214c4a546e86719312'
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
  checksum 'e166bb86652c691272417919951a3b789397c1375ea643070e41f190a6ceb05a'
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

dmg_package 'Inkscape' do
  source 'http://downloads.sourceforge.net/inkscape/Inkscape-0.48.5-2+X11.dmg'
  checksum '72191861ee19a4e047d9084c7181a5ccf6e89d9b4410e197a98c2e1027e65e72'
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

JETTISON_VERSION = '1.4.3'
dmg_package 'Jettison' do
  source "http://www.stclairsoft.com/download/Jettison-#{JETTISON_VERSION}.dmg"
  checksum '5836546099a85e212bd1cfbc79b35e5cf4d99e7056edff4a2b4fbdfdf3bdbd6a'
  volumes_dir "Jettison #{JETTISON_VERSION}"
  action :install
end
node.default['mac_os_x']['settings']['jettison'] = {
  domain: 'com.stclairsoft.Jettison',
  autoEjectAtLogout: false,
  # This really means autoEjectAtSleep.
  autoEjectEnabled: true,
  ejectDiskImages: true,
  ejectHardDisks: true,
  ejectNetworkDisks: true,
  ejectOpticalDisks: false,
  ejectSDCards: false,
  hideMenuBarIcon: false,
  playSoundOnFailure: false,
  playSoundOnSuccess: false,
  showRemountProgress: false,
  statusItemEnabled: true,
  toggleMassStorageDriver: false
}

KARABINER_VERSION = '10.6.0'
dmg_package 'Karabiner' do
  source 'https://pqrs.org/osx/karabiner/files/' \
         "Karabiner-#{KARABINER_VERSION}.dmg"
  checksum '11e671861a6fa137a8a79506718840eb0d006868f89e89b0f431e5e9b5a06854'
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

# Pandoc

# Pandoc can be installed using Homebrew, but that doesn't install the man
# pages. These are important as this is a pretty complex tool, and it's
# important to have online documentation. The tradeoff is that this
# installation pkg is a bit more complex to manage.

# Note: This installation was based on the MacTeX installation procedure.
PANDOC_VERSION = '1.13.2'
pkgutil_proc = Mixlib::ShellOut.new(
  'pkgutil', '--pkg-info', 'net.johnmacfarlane.pandoc')
pkgutil_proc.run_command
PANDOC_IS_INSTALLED = pkgutil_proc.exitstatus == 0

PANDOC_CACHE_PATH = "#{Chef::Config[:file_cache_path]}/pandoc.pkg"

# First, download the file.
remote_file 'download Pandoc pkg' do
  source 'https://github.com/jgm/pandoc/releases/download/'\
         "#{PANDOC_VERSION}/pandoc-#{PANDOC_VERSION}-osx.pkg"
  path PANDOC_CACHE_PATH
  checksum '02455fba5353568b19d8b0bebbda9b99ba2c943b3f01b11b185f25c7db111b50'
  # Don't bother downloading the file if Pandoc is already installed.
  not_if { PANDOC_IS_INSTALLED }
end

# Now install.
execute 'install Pandoc' do
  command "sudo installer -pkg '#{PANDOC_CACHE_PATH}' -target /"
  not_if { PANDOC_IS_INSTALLED }
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

XQUARTZ_VERSION = '2.7.7'
dmg_package 'XQuartz' do
  # Note: XQuartz is installed to /Applications/Utilities/XQuartz.app
  source 'http://xquartz.macosforge.org/downloads/SL/'\
         "XQuartz-#{XQUARTZ_VERSION}.dmg"
  checksum 'c9b3a373b7fd989331117acb9696fffd6b9ee1a08ba838b02ed751b184005211'
  type 'pkg'
  volumes_dir "XQuartz-#{XQUARTZ_VERSION}"
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

# SkyFonts (http://www.fonts.com/browse/font-tools/skyfonts) allows syncing of
# fonts between platforms.
dmg_package 'Monotype SkyFonts' do
  source 'http://cdn1.skyfonts.com/client/Monotype_SkyFonts_Mac64_4.7.0.0.dmg'
  checksum '4ab68c1567637f083f4739e88a1bf2c6895bd2d24c01789a2011c827474d28e5'
  # Need to use this because the app name has spaces.
  dmg_name 'MonotypeSkyFonts'
  action :install
end

# Inconsolata for Powerline (can't be installed via SkyFonts, for obvious
# reasons).
INCONSOLATA_POWERLINE_FILE = 'Inconsolata for Powerline.otf'
remote_file 'download Inconsolata for Powerline font' do
  source 'https://github.com/Lokaltog/powerline-fonts/raw/'\
         'master/Inconsolata/' + URI.escape(INCONSOLATA_POWERLINE_FILE)
  path "#{node['macosx_setup']['fonts_dir']}/#{INCONSOLATA_POWERLINE_FILE}"
end

# Mac OS X tweaks

include_recipe 'mac_os_x'

# Password-protected screensaver + delay
include_recipe 'mac_os_x::screensaver'

# Turn on the OS X firewall.
include_recipe 'mac_os_x::firewall'

# Set up clock with day of week, date, and 24-hour clock.
mac_os_x_plist_file 'com.apple.menuextra.clock.plist'

# Show percentage on battery indicator.
mac_os_x_plist_file 'com.apple.menuextra.battery.plist'

# Tweaks from
# https://github.com/kevinSuttle/OSXDefaults/blob/master/.osx
# https://github.com/mathiasbynens/dotfiles/blob/master/.osx

node.default['mac_os_x']['settings']['global'] = {
  :domain => 'NSGlobalDomain',
  # Always show scrollbars
  :AppleShowScrollBars => 'Always',
  # Increase window resize speed for Cocoa applications
  :NSWindowResizeTime => 0.001,
  # Expand save panel by default
  :NSNavPanelExpandedStateForSaveMode => true,
  :NSNavPanelExpandedStateForSaveMode2 => true,
  # Expand print panel by default
  :PMPrintingExpandedStateForPrint => true,
  :PMPrintingExpandedStateForPrint2 => true,
  # Save to disk (not to iCloud) by default
  :NSDocumentSaveNewDocumentsToCloud => false,
  # Disable natural (Lion-style) scrolling
  'com.apple.swipescrolldirection' => false,
  # Display ASCII control characters using caret notation in standard text
  # views
  # Try e.g. `cd /tmp; echo -e '\x00' > cc.txt; open -e cc.txt`
  :NSTextShowsControlCharacters => true,
  # Disable press-and-hold for keys in favor of key repeat
  :ApplePressAndHoldEnabled => false,
  # Set a blazingly fast keyboard repeat rate
  :KeyRepeat => 0,
  # Finder
  ## Show all filename extensions
  :AppleShowAllExtensions => true,
  ## Enable spring loading for directories
  'com.apple.springing.enabled' => true,
  # Remove the spring loading delay for directories
  'com.apple.springing.delay' => 0.0
}

# Automatically quit printer app once the print jobs complete
node.default['mac_os_x']['settings']['print'] = {
  :domain => 'com.apple.print.PrintingPrefs',
  'Quit When Finished' => true
}

# Set Help Viewer windows to non-floating mode
node.default['mac_os_x']['settings']['helpviewer'] = {
  domain: 'com.apple.helpviewer',
  DevMode: true
}

# Reveal IP address, hostname, OS version, etc. when clicking the clock in the
# login window
node.default['mac_os_x']['settings']['loginwindow'] = {
  domain: '/Library/Preferences/com.apple.loginwindow',
  AdminHostInfo: 'HostName'
}

# More Finder tweaks
# Note: Quitting Finder will also hide desktop icons.
node.default['mac_os_x']['settings']['finder'] = {
  domain: 'com.apple.finder',
  # Allow quitting via Command-Q
  QuitMenuItem: true,
  # Disable window animations and Get Info animations
  DisableAllAnimations: true,
  # Don't show hidden files by default -- this shows hidden files on the
  # desktop, which is just kind of annoying. I've haven't really seen other
  # benefits, since I don't use Finder much.
  AppleShowAllFiles: false,
  # Show status bar
  ShowStatusBar: true,
  # Show path bar
  ShowPathbar: true,
  # Allow text selection in Quick Look
  QLEnableTextSelection: true,
  # Display full POSIX path as Finder window title
  _FXShowPosixPathInTitle: true,
  # When performing a search, search the current folder by default
  FXDefaultSearchScope: 'SCcf',
  # Disable the warning when changing a file extension
  FXEnableExtensionChangeWarning: false,
  # Use list view in all Finder windows by default
  # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
  FXPreferredViewStyle: 'Nlsv'
}

# Avoid creating .DS_Store files on network
node.default['mac_os_x']['settings']['desktopservices'] = {
  domain: 'com.apple.desktopservices',
  DSDontWriteNetworkStores: true
}

node.default['mac_os_x']['settings']['networkbrowser'] = {
  domain: 'com.apple.NetworkBrowser',
  # Enable AirDrop over Ethernet and on unsupported Macs running Lion
  BrowseAllInterfaces: true
}

node.default['mac_os_x']['settings']['dock'] = {
  # Remove the auto-hiding Dock delay
  'autohide-delay' => 0.0,
  # Remove the animation when hiding/showing the Dock
  'autohide-time-modifier' => 0.0,
  # Automatically hide and show the Dock
  :autohide => true,
  # Make Dock icons of hidden applications translucent
  :showhidden => true
}

node.default['mac_os_x']['settings']['timemachine'] = {
  domain: 'com.apple.TimeMachine',
  # Prevent Time Machine from prompting to use new hard drives as backup volume
  DoNotOfferNewDisksForBackup: true
}

node.default['mac_os_x']['settings']['textedit'] = {
  # Use plain text mode for new TextEdit documents
  domain: 'com.apple.TextEdit',
  RichText: 0,
  # Open and save files as UTF-8 in TextEdit
  PlainTextEncoding: 4,
  PlainTextEncodingForWrite: 4
}

node.default['mac_os_x']['settings']['diskutil'] = {
  :domain => 'com.apple.DiskUtility',
  # Enable the debug menu in Disk Utility
  :DUDebugMenuEnabled => true,
  # enable the advanced image menu in Disk Utility
  'advanced-image-options' => true
}

# Actually write all the settings using the 'defaults' command.
include_recipe 'mac_os_x::settings'
