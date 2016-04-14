# -*- coding: utf-8 -*-
#
# Cookbook Name:: osx_setup
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
require 'json'
require 'pathname'

# Including this causes Homebrew to install if not already installed (needed
# for the next section) and to run `brew update' if already installed.
include_recipe 'homebrew'

###############################################################################
# SHELLS
###############################################################################

BREW_PREFIX = shell_out!('brew', '--prefix').stdout.rstrip

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
node.osx_setup.shells.each do |shell|
  # Install the shell using Homebrew.
  package shell do
    action :install
  end

  shell_path = File.join(BREW_PREFIX, 'bin', shell)
  # First, add shell to shells config file so it is recognized as a valid user
  # shell.
  execute "add #{shell_path} to #{node.osx_setup.etc_shells}" do
    # Unfortunately, using a ruby_block does not work because there's no way
    # that I know to execute it using sudo.
    command ['sudo', 'bash', '-c',
             "echo '#{shell_path}' >> '#{node.osx_setup.etc_shells}'"]
    not_if do
      # Don't execute if this shell is already in the shells config file. Open
      # a new file each time to reset the enumerator, and just in case these
      # are executed in parallel.
      File.open(node.osx_setup.etc_shells).each_line.any? do |line|
        line.include?(shell_path)
      end
    end
  end
end

# Then, set zsh as the current user's shell.
lambda do
  path = File.join(BREW_PREFIX, 'bin', 'zsh')
  execute "set #{path} as default shell" do
    command ['chsh', '-s', path]
    # getpwuid defaults to the current user, which is what we want.
    not_if { Etc.getpwuid.shell == path }
  end
end.call

# Make sure to use the `execute' resource than the `bash' resource, otherwise
# sudo cannot prompt for a password.
execute 'fix the zsh startup file that path_helper uses' do
  # OS X has a program called path_helper that allows paths to be easily set
  # for multiple shells. For bash (and other shells), it works great because it
  # is called /etc/profile which is executed only for login shells. However,
  # with zsh, path_helper is run from /etc/zshenv *instead of* /etc/zprofile
  # like it should be. This fixes Apple's mistake.
  #
  # See this link for more information:
  # <https://github.com/sorin-ionescu/prezto/issues/381>
  command ['sudo', 'mv', '/etc/zshenv', '/etc/zprofile']
  only_if { File.exist?('/etc/zshenv') }
end

###############################################################################
# HOMEBREW FORMULAS AND CASKS
###############################################################################

homebrew_tap 'homebrew/command-not-found'

# Install Emacs with options. Do this before installing the other formulas,
# because the cask formula depends on emacs.
package 'emacs' do
  # Building with glib allows file notification support.
  options '--cocoa --with-gnutls --with-glib'
end
execute "Link 'Emacs.app' to '/Applications'" do
  command %w(brew linkapps emacs)
  creates '/Applications/Emacs.app'
end

# git-grep PCRE. Do this before installing other formulas in
# case there is a dependency on git.
package 'git' do
  options '--with-pcre'
end

# LastPass command-line interface
package 'lastpass-cli' do
  options '--with-doc --with-pinentry'
end

# mitmproxy with options
#
# There is a cask for this as well, but it is out-of-date. We also want to make
# sure the extras are included.
# XXX: This is broken as of 2016-04-14
# package 'mitmproxy' do
#   options '--with-cssutils --with-protobuf --with-pyamf'
# end

# Ettercap with IPv6 support, GTK+ GUI, and Ghostscript (for PDF docs)
#
# Note: Ettercap is crashing at this time on my Mac, so I've disabled it for
# now. Hopefully there is a solution in the future.
#
# Note: When initially installing, I had a problem with this Ghostscript
# conflicting with Ghostscript from MacTeX, I believe. I just overwrote it, but
# this may be a problem again when installing fresh.
#
# package 'ettercap' do
#   options '--with-ghostscript --with-gtk+ --with-ipv6'
# end

include_recipe 'homebrew::install_formulas'
include_recipe 'homebrew::install_casks'

###############################################################################
# CUSTOM INSTALLS
###############################################################################

# Deep Sleep Dashboard widget

# The original version (http://deepsleep.free.fr/) is unfortunately broken for
# newer Macs as the hibernate modes have changed. However, CODE2K has updated
# the widget for Mountain Lion (and Mavericks)
# (http://code2k.net/blog/2012-11-06/).
lambda do
  archive_name = 'deepsleep-1.3-beta1.zip'
  archive_path = "#{Chef::Config[:file_cache_path]}/#{archive_name}"

  # This isn't perfect -- the widget will only download and install when the
  # archive file doesn't exist.
  remote_file 'download Deep Sleep dashboard widget' do
    source 'https://github.com/downloads/code2k/Deep-Sleep.wdgt/' +
      archive_name
    checksum 'fa41a926d7c1b6566b074579bdd4c9bc969d348292597ac3064731326efc4207'
    path archive_path
    notifies :run, 'execute[install Deep Sleep dashboard widget]'
  end

  execute 'install Deep Sleep dashboard widget' do
    command ['unzip', '-o', archive_path]
    cwd "#{node.osx_setup.home}/Library/Widgets"
    action :nothing
  end
end.call

# Tasks Explorer, distributed as a pkg file not inside a DMG.
#
# All pkg ids installed:
#
#     com.macosinternals.tasksexplorer.Contents.pkg
#     com.macosinternals.tasksexplorer.tasksexplorerd.pkg
#     com.macosinternals.tasksexplorer.com.macosinternals.tasksexplorerd.pkg
#
# We only check for the first one, though.
lambda do
  is_installed = shell_out(
    'pkgutil', '--pkg-info', 'com.macosinternals.tasksexplorer.Contents.pkg'
  ).exitstatus == 0
  pkg_path = "#{Chef::Config[:file_cache_path]}/Tasks Explorer.pkg"
  # First, download the file.
  remote_file 'download Tasks Explorer pkg' do
    source 'https://github.com/astavonin/Tasks-Explorer/blob/master/release/' \
           'Tasks%20Explorer.pkg?raw=true'
    path pkg_path
    checksum '8fa4fff39a6cdea368e0110905253d7fb9e26e36bbe053704330fe9f24f7db6a'
    # Don't bother downloading the file if Tasks Explorer is already installed.
    not_if { is_installed }
  end
  # Now install.
  execute 'install Tasks Explorer' do
    # With some help from:
    # - https://github.com/opscode-cookbooks/dmg/blob/master/providers/package.rb
    # - https://github.com/mattdbridges/chef-osx_pkg/blob/master/providers/package.rb
    command ['sudo', 'installer', '-pkg', pkg_path, '-target', '/']
    not_if { is_installed }
  end
end.call

# Ubuntu fonts
#
# The regular Ubuntu font can be installed with SkyFonts, but it doesn't
# include Ubuntu Mono, which we want.
lambda do
  archive_name = 'ubuntu-font-family-0.83.zip'
  archive_path =
    "#{Chef::Config[:file_cache_path]}/#{archive_name}"
  install_dir = "#{node.osx_setup.fonts_dir}/Ubuntu"

  directory install_dir

  remote_file 'download Ubuntu fonts' do
    source "http://font.ubuntu.com/download/#{archive_name}"
    path archive_path
    checksum '456d7d42797febd0d7d4cf1b782a2e03680bb4a5ee43cc9d06bda172bac05b42'
    notifies :run, 'execute[install Ubuntu fonts]'
  end

  execute 'install Ubuntu fonts' do
    command "unzip '#{archive_path}'"
    cwd install_dir
    action :nothing
  end
end.call

# Inconsolata for Powerline (can't be installed via SkyFonts, for obvious
# reasons).
remote_file 'download Inconsolata for Powerline font' do
  filename = 'Inconsolata for Powerline.otf'
  source 'https://github.com/powerline/fonts/raw/master/Inconsolata/' +
    URI.escape(filename)
  path "#{node.osx_setup.fonts_dir}/#{filename}"
end

###############################################################################
# PREFERENCES
###############################################################################

# Password-protected screensaver + delay
include_recipe 'mac_os_x::screensaver'

# Turn on the OS X firewall.
include_recipe 'mac_os_x::firewall'

# Actually write all the settings using the 'defaults' command.
include_recipe 'mac_os_x::settings'

# Show percentage on battery indicator.
#
# Note: For some reason, Apple chose the value of ShowPercent to be 'YES' or
# 'NO' as a string instead of using a boolean. mac_os_x_userdefaults treats
# 'YES' as a boolean when reading, making it overwrite every time. For this
# reason, we just write the plist.
mac_os_x_plist_file 'com.apple.menuextra.battery.plist'

# iTerm2
#
# There is a Chef cookbook for iterm2, but we've chosen to install using
# Homebrew Cask. The iterm2 cookbook can install tmux integration, but it's
# apparently spotty, and I haven't wanted tmux integration anyway. It also
# raises an annoying error because it looks for the plist in its own cookbook.
#
# Install background images.
directory node.osx_setup.iterm2.bgs_dir
json_content = JSON.pretty_generate(
  Profiles: node.osx_setup.iterm2.profiles.map do |profile|
    profile = profile.dup
    bg_key = node.osx_setup.iterm2.bg_key
    if profile.key?(bg_key) && Pathname.new(profile[bg_key]).relative?
      base = profile[bg_key]
      cookbook_path = "iterm2-bgs/#{base}"
      install_path =
        "#{node.osx_setup.iterm2.bgs_dir}/#{base}"
      profile[bg_key] = install_path
      cookbook_file "install iTerm2 background '#{base}'" do
        source cookbook_path
        path install_path
      end
    end
    profile
  end
)
# Install dynamic profiles.
directory node.osx_setup.iterm2.dynamic_profiles_dir
file 'install iTerm2 dynamic profiles' do
  path node.osx_setup.iterm2.dynamic_profiles_dir +
    '/InstalledByChef.json'
  content json_content
end

cookbook_file 'Karabiner XML settings file' do
  source 'Karabiner_private.xml'
  path "#{node.osx_setup.home}/Library/Application Support/" \
       'Karabiner/private.xml'
end

cookbook_file 'Quicksilver catalog preferences file' do
  source 'Quicksilver-Catalog.plist'
  path node.osx_setup.home +
    '/Library/Application Support/Quicksilver/Catalog.plist'
end

cookbook_file 'Slate preferences file' do
  source 'slate.js'
  path "#{node.osx_setup.home}/.slate.js"
end

# Set Skim as default PDF reader using duti.
execute 'set Skim as PDF viewer' do
  current_pdf_app = shell_out!('duti', '-x', 'pdf').stdout.lines[0].rstrip
  # Note: Although setting the default app for 'viewer' instead of 'all' works
  # and makes more sense, there is apparently no way to query this information
  # using duti. Since we won't really be editing PDFs, we'll just set the role
  # to 'all' for Skim.
  command %w(duti -s net.sourceforge.skim-app.skim pdf all)
  not_if { current_pdf_app == 'Skim.app' }
end

execute 'invalidate sudo timestamp' do
  # 'sudo -K' will remove the timestamp entirely, which means that sudo will
  # print the initial 'Improper use of the sudo command' warning. Not what we
  # want. 'sudo -k' just invalidates the timestamp without removing it.
  command ['sudo', '-k']
  # Kill only if we have sudo privileges. 'sudo -k' is idempotent anyway, but
  # it's nice to see less resources updated when possible.
  #
  # 'sudo -n command' exits with 0 if a password is needed (what?), or the exit
  # code of 'command' if it is able to run it. Hence the unusual guard here: an
  # exit code of 1 indicates sudo privileges, while 0 indicates none.
  not_if ['sudo', '-n', 'false']
end
