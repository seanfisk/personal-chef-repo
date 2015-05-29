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

# Including this causes Homebrew to install if not already installed (needed
# for the next section) and to run `brew update' if already installed.
include_recipe 'homebrew'

###############################################################################
# SHELLS
###############################################################################

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
%w(bash zsh).each do |shell|
  # Install the shell using Homebrew.
  package shell do
    action :install
  end

  shell_path = File.join(BREW_PREFIX, 'bin', shell)
  # First, add shell to /etc/shells so it is recognized as a valid user shell.
  execute "add #{shell_path} to #{SHELLS_FILE}" do
    # Unfortunately, using a ruby_block does not work because there's no way
    # that I know to execute it using sudo.
    command "sudo bash -c \"echo '#{shell_path}' >> '#{SHELLS_FILE}'\""
    not_if do
      # Don't execute if this shell is already in the shells config file. Open
      # a new file each time to reset the enumerator, and just in case these
      # are executed in parallel.
      File.open(SHELLS_FILE).each_line.any? do
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

###############################################################################
# HOMEBREW FORMULAS
###############################################################################

# Install Emacs with options. Do this before installing the other formulas,
# because the cask formula depends on emacs.
package 'emacs' do
  options '--cocoa --with-gnutls'
end
execute "Link 'Emacs.app' to '/Applications'" do
  command 'brew linkapps emacs'
  creates '/Applications/Emacs.app'
end

# git-grep PCRE. Do this before installing other formulas in
# case there is a dependency on git.
package 'git' do
  options '--with-pcre'
end

node.default['homebrew']['formulas'] = [
  'ack',
  'aria2',
  'astyle',
  'cask',
  'coreutils',
  # An improved version of df with colors.
  'dfc',
  # Dos2Unix / Unix2Dos <http://waterlan.home.xs4all.nl/dos2unix.html> looks
  # superior to Tofrodos <http://www.thefreecountry.com/tofrodos/>. But that
  # was just from a quick look.
  'dos2unix',
  'doxygen',
  'editorconfig',
  'fasd',
  'gibo',
  'gnu-tar',
  # Install both GraphicMagick and ImageMagick. In generally, I prefer
  # GraphicsMagick, but ImageMagick has ICO support so we use it for
  # BetterPlanner.
  'graphicsmagick',
  'graphviz',
  'grc',
  'htop-osx',
  'hub',
  # ImageMagick might already be present on the system (but just 'convert').
  # I'm not sure if it's just an artifact of an earlier build, but it was on my
  # Mavericks system before I installed it (again?).
  'imagemagick',
  # For pygit2 (which is for Powerline).
  'libgit2',
  'markdown',
  'mercurial',
  'mobile-shell',
  'mr', # myrepos, for managing multiple repos
  'nmap',
  'node',
  # I prefer ohcount to cloc and sloccount.
  'ohcount',
  'p7zip',
  'parallel',
  'pdfgrep',
  'pstree',
  # pwgen and sf-pwgen are both password generators. pwgen is more generic,
  # whereas sf-pwgen uses Apple's security framework. We also looked at APG,
  # but it seems unmaintained.
  'pwgen',
  'sf-pwgen',
  'pyenv',
  'pyenv-virtualenv',
  'pyenv-which-ext',
  'qpdf',
  # Even though the rbenv cookbooks looks nice, they don't work as I'd like.
  # fnichol's supports local install, but insists on templating
  # /etc/profile.d/rbenv.sh *even when doing a local install*. That makes no
  # sense. I don't want that.
  #
  # The RiotGames rbenv cookbook only supports global install.
  #
  # So let's just install through trusty Homebrew.
  #
  # We now also install pyenv through Homebrew, so it's nice to be consistent.
  'rbenv',
  # reattach-to-user-namespace has options to fix launchctl and shim
  # pbcopy/pbaste. We haven't needed them yet, though.
  'reattach-to-user-namespace',
  'renameutils',
  'ruby-build',
  'ssh-copy-id',
  # Primarily for Sphinx
  'texinfo',
  'the_silver_searcher',
  'tmux',
  'tree',
  'valgrind',
  'watch',
  'wget',
  'xclip',
  'xz',
  'youtube-dl',
  # ZeroMQ (zmq) is included to speed up IPython installs. It can install a
  # bundled version to a virtualenv, but it's faster to have a globally built
  # version.
  'zmq',
  # Fun commands!
  'cmatrix',
  'cowsay',
  'figlet',
  'fortune',
  'ponysay',
  'sl',
  'toilet'
]

include_recipe 'homebrew::install_formulas'

###############################################################################
# HOMEBREW CASKS (see http://caskroom.io/)
###############################################################################

node.default['homebrew']['casks'] = [
  'adium',
  'adobe-reader',
  'atext',
  'caffeine',
  'cathode',
  'chicken',
  'cord',
  'dash',
  'deeper',
  'disk-inventory-x',
  # There are a number of different versions of Eclipse. The eclipse-ide cask,
  # described as 'Eclipse IDE for Eclipse Committers', is actually just the
  # standard package without any extras. This is nice, because extras can
  # always be installed using the Eclipse Marketplace.
  'eclipse-ide',
  'firefox',
  'flash',
  'flash-player',
  'flux',
  'gfxcardstatus',
  'gimp',
  'google-chrome',
  'inkscape',
  'iterm2',
  'jettison',
  'karabiner',
  # This cask already applies the fix as shown here:
  # https://github.com/osxfuse/osxfuse/wiki/SSHFS#macfusion
  'macfusion',
  'monotype-skyfonts',
  'openemu',
  'osxfuse',
  # Pandoc can be installed with a Homebrew formula, but that doesn't install
  # the man pages. These are important as this is a pretty complex tool, and
  # it's important to have online documentation.
  'pandoc',
  'quicksilver',
  'remote-desktop-connection',
  'skim',
  'skitch',
  'slate',
  'sshfs',
  # The silverlight cask is having some checksum issues.
  # 'silverlight',
  'vagrant',
  'virtualbox',
  # Wireshark initially used GTK+ as the GUI library, but is switching to Qt.
  # According to their blog post announcement:
  #
  #     If you're running OS X you should use the Qt flavor. For common tasks it
  #     should have a better workflow. Again, if it doesn't we aren't doing our
  #     job.
  #
  # Source: https://blog.wireshark.org/2013/10/switching-to-qt/
  #
  # However, the 'Capture Filters...' and 'Display Filters...' dialogs are not
  # implemented as of development release 1.99.1, which uses Qt. These are
  # pretty important for a beginner like me, so I've decided to stick with GTK+
  # and X11 for now. When these are implemented, switch to Qt :)
  #
  # See: https://ask.wireshark.org/questions/33478/filter-box-not-working-on-qt-wireshark-on-os-x
  'wireshark',
  # Note: XQuartz is installed to /Applications/Utilities/XQuartz.app
  'xquartz'
]

include_recipe 'homebrew::install_casks'

###############################################################################
# CUSTOM INSTALLS
###############################################################################

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

# Tasks Explorer, distributed as a pkg file not inside a DMG.
#
# All pkg ids installed:
#
#     com.macosinternals.tasksexplorer.Contents.pkg
#     com.macosinternals.tasksexplorer.tasksexplorerd.pkg
#     com.macosinternals.tasksexplorer.com.macosinternals.tasksexplorerd.pkg
#
# We only check for the first one, though.
pkgutil_proc = Mixlib::ShellOut.new(
  'pkgutil', '--pkg-info', 'com.macosinternals.tasksexplorer.Contents.pkg')
pkgutil_proc.run_command
TE_IS_INSTALLED = pkgutil_proc.exitstatus == 0
TE_PKG_CACHE_PATH = "#{Chef::Config[:file_cache_path]}/Tasks Explorer.pkg"
# First, download the file.
remote_file 'download Tasks Explorer pkg' do
  source 'https://github.com/astavonin/Tasks-Explorer/blob/master/release/' \
         'Tasks%20Explorer.pkg?raw=true'
  path TE_PKG_CACHE_PATH
  checksum '8fa4fff39a6cdea368e0110905253d7fb9e26e36bbe053704330fe9f24f7db6a'
  # Don't bother downloading the file if Tasks Explorer is already installed.
  not_if { TE_IS_INSTALLED }
end
# Now install.
execute 'install Tasks Explorer' do
  # rubocop:disable LineLength
  #
  # With some help from:
  # - https://github.com/opscode-cookbooks/dmg/blob/master/providers/package.rb
  # - https://github.com/mattdbridges/chef-osx_pkg/blob/master/providers/package.rb
  #
  # rubocop:enable LineLength
  command "sudo installer -pkg '#{TE_PKG_CACHE_PATH}' -target /"
  not_if { TE_IS_INSTALLED }
end

# Inconsolata for Powerline (can't be installed via SkyFonts, for obvious
# reasons).
INCONSOLATA_POWERLINE_FILE = 'Inconsolata for Powerline.otf'
remote_file 'download Inconsolata for Powerline font' do
  source 'https://github.com/Lokaltog/powerline-fonts/raw/'\
         'master/Inconsolata/' + URI.escape(INCONSOLATA_POWERLINE_FILE)
  path "#{node['macosx_setup']['fonts_dir']}/#{INCONSOLATA_POWERLINE_FILE}"
end

###############################################################################
# PREFERENCES
###############################################################################

# Password-protected screensaver + delay
include_recipe 'mac_os_x::screensaver'

# Turn on the OS X firewall.
include_recipe 'mac_os_x::firewall'

# Allow keyboard access to all controls (using Tab), not just text boxes and
# lists.
include_recipe 'mac_os_x::kbaccess'

# Set up clock with day of week, date, and 24-hour clock.
node.default['mac_os_x']['settings']['clock'] = {
  domain: 'com.apple.menuextra.clock',
  DateFormat: 'EEE MMM d  H:mm',
  FlashDateSeparators: false,
  IsAnalog: false
}

# Show percentage on battery indicator.
#
# Note: For some reason, Apple chose the value of ShowPercent to be 'YES' or
# 'NO' as a string instead of using a boolean. mac_os_x_userdefaults treats
# 'YES' as a boolean when reading, making it overwrite every time. For this
# reason, we just write the plist.
mac_os_x_plist_file 'com.apple.menuextra.battery.plist'

node.default['mac_os_x']['settings']['atext'] = {
  domain: 'com.trankynam.aText',
  # Most of aText's settings are [presumably] stored in a giant data blob.
  # XXX These settings are dubiously applied.
  PlayFeedbackSound: false,
  ShowDockIcon: false
}

node.default['mac_os_x']['settings']['caffeine'] = {
  domain: 'com.lightheadsw.caffeine',
  ActivateOnLaunch: true, # Turn on Caffeine when the app is started.
  DefaultDuration: 0, # Activate indefinitely
  SuppressLaunchMessage: true
}

node.default['mac_os_x']['settings']['cathode'] = {
  domain: 'com.secretgeometry.Cathode',
  # Console and Monitor themes themselves seem not to be stored in preferences.
  CloseOnExit: false,
  JitterWhenWindowMoves: true,
  PositionalPerspective: true,
  RenderingQuality: 3, # High
  UseColorPalette: true,
  UseOptionAsMeta: true,
  UseSounds: false
}

node.default['mac_os_x']['settings']['gfxcardstatus'] = {
  domain: 'com.codykrieger.gfxCardStatus-Preferences',
  shouldCheckForUpdatesOnStartup: true,
  shouldUseSmartMenuBarIcons: true
  # Note: shouldStartAtLogin doesn't actually work, because gfxCardStatus uses
  # login items like most other applications. So don't bother setting it.
}

# iTerm2
#
# There is a Chef cookbook for iterm2, but we've chosen to install using
# Homebrew Cask. The iterm2 cookbook can install tmux integration, but it's
# apparently spotty, and I haven't wanted tmux integration anyway. It also
# raises an annoying error because it looks for the plist in its own cookbook.

## Install background image.
backgrounds_dir = "#{node['macosx_setup']['home']}/Pictures/Backgrounds"
background_name = 'holland-beach-sunset.jpg'
background_path = "#{backgrounds_dir}/#{background_name}"

directory backgrounds_dir
cookbook_file background_name do
  path background_path
end

## Install plist, containing lots of themes, configuration, and background
## image setup.
##
## We've considered using defaults, but mac_os_x_userdefaults doesn't support
## nested dictionary values. iTerm2 preferences use this, so we need to keep
## using the template. Even if in the future mac_os_x_userdefaults gains nested
## dictionary support, it builds command lines to 'defaults', which might
## exceed the OS limit for command lines.
##
## Another option would be to merge part of the plist using
## /usr/libexec/PlistBuddy.
template 'iTerm2 preferences file' do
  source 'com.googlecode.iterm2.plist.erb'
  path "#{node['macosx_setup']['home']}/Library/Preferences/" \
       'com.googlecode.iterm2.plist'
  variables(
    background_image_path: background_path,
    home_directory: node['macosx_setup']['home']
  )
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
  moveToApplicationsFolderAlertSuppress: true,
  playSoundOnFailure: false,
  playSoundOnSuccess: false,
  showRemountProgress: false,
  statusItemEnabled: true,
  toggleMassStorageDriver: false
}

cookbook_file 'Karabiner XML settings file' do
  source 'Karabiner_private.xml'
  path "#{node['macosx_setup']['home']}/Library/Application Support/" \
       'Karabiner/private.xml'
end

# Note: We are not setting the Quicksilver hotkey through these settings.
#
# It was easy to do when we just copied the plist, but the plist has the
# disadvantage of replacing *all* of the settings.
#
# However, the mac_os_x_userdefaults provider does not support dictionaries
# with integer values, so it's not currently possible to set the hotkey through
# that either.
#
# We could run this command manually:
#
#     defaults write com.blacktree.Quicksilver QSActivationHotKey \
#     -dict keyCode -int 49 modifiers -int 524576
#
# However, the idempotency check presents a problem, since 'defaults read'
# displays both an integer and string in the same way. The 'defaults read'
# command also does not support descending into a dictionary to read a value.
# These are weaknesses of the defaults command-line interface, I guess.
#
# However, /usr/libexec/PlistBuddy can descend into dictionaries, and can print
# out type information when using the XML output option (-x). This gets ugly
# quickly, though, as PlistBuddy is somewhat cumbersome, and also might not
# play well with cached preferences.
#
# The most correct way to do this with an idempotence check that I can see
# would be to use the NSUserDefaults Cocoa class [1] to read the values
# programatically. The easiest way I can see to do this is to use the cocoa gem
# [2]. In this way, we are playing with real data types, and not shuffling them
# through an inaccurate command-line interface.
#
# However, with all these options being very complicated, we've decided just to
# leave it unautomated for now. The story of the adventure is left here for
# posterity.
#
# [1]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/UserDefaults/AccessingPreferenceValues/AccessingPreferenceValues.html
# [2]: https://rubygems.org/gems/cocoa
#
node.default['mac_os_x']['settings']['quicksilver'] = {
  :domain => 'com.blacktree.Quicksilver',
  'Check for Updates' => true,
  'Hide Dock Icon' => true,
  :QSAgreementAccepted => true,
  :QSCommandInterfaceControllers => 'QSBezelInterfaceController',
  :QSShowMenuIcon => true,
  :QSUseFullMenuStatusItem => false,
  'Setup Assistant Completed' => true
}

# TODO: Consider using JavaScript preferences (replacing .slate, or to
# supplement it).
cookbook_file 'Slate preferences file' do
  source 'slate'
  path "#{node['macosx_setup']['home']}/.slate"
end

node.default['mac_os_x']['settings']['tasks_explorer'] = {
  domain: 'com.macosinternals.Tasks-Explorer',
  highlight_processes: true,
  show_kernel_cpu_time: true,
  update_frequency: 2 # 2 seconds
}

node.default['mac_os_x']['settings']['xquartz'] = {
  domain: 'org.macosforge.xquartz.X11',
  # Input
  enable_fake_buttons: false,
  sync_keymap: false,
  enable_key_equivalents: true,
  option_sends_alt: true,
  # Output
  depth: '-1', # use colors from display
  rootless: true,
  fullscreen_menu: true,
  # Pasteboard
  ## Syncing is somewhat broken, see here:
  ## <http://xquartz.macosforge.org/trac/ticket/765>
  ## If you go into XQuartz and press Cmd-C it will usually sync it.
  sync_pasteboard: true,
  sync_clipboard_to_pasteboard: true,
  sync_pasteboard_to_clipboard: true,
  sync_pasteboard_to_primary: true,
  sync_primary_on_select: false,
  # Windows
  wm_click_through: false,
  wm_ffm: false,
  wm_focus_on_new_window: true,
  # Security
  no_auth: false,
  nolisten_tcp: true,
  # Other
  login_shell: ZSH_PATH # XXX seems to do nothing, xterm still starts /bin/sh
}

# Tweaks from
# https://github.com/kevinSuttle/OSXDefaults/blob/master/.osx
# https://github.com/mathiasbynens/dotfiles/blob/master/.osx

# A note on settings: if the value is zero, set it as an integer 0 instead of
# float 0.0. Otherwise, it will be "cast" to a float by the defaults system and
# the resource will be updated every time. In addition, if the dock settings
# are updated, the mac_os_x cookbook will `killall dock' every time.

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
  # Key repeat
  # This is also possible through the mac_os_x::key_repeat recipe, but having
  # it here allows customization of the values.
  ## Set a keyboard repeat rate to fast
  :KeyRepeat => 2,
  ## Set low initial delay
  :InitialKeyRepeat => 15,
  # Finder
  ## Show all filename extensions
  :AppleShowAllExtensions => true,
  ## Enable spring loading for directories
  'com.apple.springing.enabled' => true,
  # Remove the spring loading delay for directories
  'com.apple.springing.delay' => 0
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
  :domain => 'com.apple.dock',
  # Remove the auto-hiding Dock delay
  'autohide-delay' => 0,
  # Remove the animation when hiding/showing the Dock
  'autohide-time-modifier' => 0,
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

# My own tweaks

node.default['mac_os_x']['settings']['universalaccess'] = {
  domain: 'com.apple.universalaccess',
  # All closeView keys control the screen zoom.
  ## 'Zoom style' choices:
  ##
  ##     0. Fullscreen
  ##     1. Picture-in-picture
  ##
  ## Don't set this. Fullscreen is the default anyway, and this way we can let
  ## the user change based upon needs at that point. We have fullscreen and PIP
  ## settings later as well.
  # closeViewZoomMode: 0,
  closeViewHotkeysEnabled: false,
  ## Use scroll gesture with modifier keys to zoom.
  closeViewScrollWheelToggle: true,
  ## Use Ctrl as the modifier key (the number is a key code or something).
  ## This seems not to work correctly (?).
  # closeViewScrollWheelModifiersInt: 262_144,
  closeViewSmoothImages: true,
  ## Don't follow *keyboard* focus.
  closeViewZoomFollowsFocus: false,
  ## Fullscreen zoom settings
  ### Choices: When zoomed in, the screen image moves:
  ###
  ###     0. Continuously with pointer
  ###     1. Only when the pointer reaches an edge
  ###     2. So the pointer is at or near the center of the screen
  closeViewPanningMode: 1,
  ## Picture-in-picture settings
  ### Use system cursor in zoom.
  closeViewCursorType: 0,
  ### Enable temporary zoom (with Ctrl-Cmd)
  closeViewPressOnReleaseOff: true,
  ### Choices:
  ###
  ###     1. Stationary
  ###     2. Follow mouse cursor
  ###     3. Tiled along edge
  closeViewWindowMode: 1
}

# Actually write all the settings using the 'defaults' command.
include_recipe 'mac_os_x::settings'

###############################################################################
# DOTFILES AND EMACS
###############################################################################

directory node['macosx_setup']['personal_dir'] do
  recursive true
  action :create
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

execute 'invalidate sudo timestamp' do
  # 'sudo -K' will remove the timestamp entirely, which means that sudo will
  # print the initial 'Improper use of the sudo command' warning. Not what we
  # want. 'sudo -k' just invalidates the timestamp without removing it.
  command 'sudo -k'
  # Kill only if we have sudo privileges. 'sudo -k' is idempotent anyway, but
  # it's nice to see less resources updated when possible.
  #
  # 'sudo -n command' exits with 0 if a password is needed (what?), or the exit
  # code of 'command' if it is able to run it. Hence the unusual guard here: an
  # exit code of 1 indicates sudo privileges, while 0 indicates none.
  not_if 'sudo -n false'
end
