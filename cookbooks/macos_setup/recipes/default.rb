# -*- coding: utf-8 -*-
#
# Cookbook Name:: macos_setup
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

CURRENT_USER = Etc.getpwuid

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
node['macos_setup']['shells'].each do |shell|
  # Install the shell using Homebrew.
  package shell do
    action :install
  end

  shell_path = File.join(BREW_PREFIX, 'bin', shell)
  # First, add shell to shells config file so it is recognized as a valid user
  # shell.
  execute "add #{shell_path} to #{node['macos_setup']['etc_shells']}" do
    # Unfortunately, using a ruby_block does not work because there's no way
    # that I know to execute it using sudo.
    command ['sudo', 'bash', '-c',
             "echo '#{shell_path}' >> '#{node['macos_setup']['etc_shells']}'"]
    not_if do
      # Don't execute if this shell is already in the shells config file. Open
      # a new file each time to reset the enumerator, and just in case these
      # are executed in parallel.
      File.open(node['macos_setup']['etc_shells']).each_line.any? do |line|
        line.include?(shell_path)
      end
    end
  end
end

# Then, set zsh as the current user's shell.
lambda do
  path = File.join(BREW_PREFIX, 'bin', 'zsh')
  execute "set #{path} as default shell" do
    command %W(chsh -s #{path})
    # getpwuid defaults to the current user, which is what we want.
    not_if { CURRENT_USER.shell == path }
  end
end.call

# Make sure to use the `execute' resource than the `bash' resource, otherwise
# sudo cannot prompt for a password.
execute 'fix the zsh startup file that path_helper uses' do
  # macOS has a program called path_helper that allows paths to be easily set
  # for multiple shells. For bash (and other shells), it works great because it
  # is called /etc/profile which is executed only for login shells. However,
  # with zsh, path_helper is run from /etc/zshenv *instead of* /etc/zprofile
  # like it should be. This fixes Apple's mistake.
  #
  # See this link for more information:
  # <https://github.com/sorin-ionescu/prezto/issues/381>
  command %w(sudo mv /etc/zshenv /etc/zprofile)
  only_if { File.exist?('/etc/zshenv') }
end

###############################################################################
# RUBY MANAGEMENT
###############################################################################

if node['macos_setup']['ruby_manager'] == 'rvm'
  # Use RVM if requested
  default_ruby = 'ruby-2.3.1'
  node.default['rvm']['user_installs'] = [
    { 'user' => CURRENT_USER.name,
      'default_ruby' => default_ruby,
      'rubies' => [
        default_ruby, # Regular development
        'ruby-2.2.1', # Current front-end
        'ruby-2.2.5', # Current collector (and hopefully future front-end)
        'jruby'       # Data providers
      ] }
  ]
  include_recipe 'rvm::user'
else
  # Use rbenv by default
  node.default['homebrew']['formulas'] += [
    # Even though the rbenv cookbooks looks nice, they don't work as I'd
    # like. fnichol's supports local install, but insists on templating
    # /etc/profile.d/rbenv.sh *even when doing a local install*. That makes
    # no sense. I don't want that.
    #
    # The RiotGames rbenv cookbook only supports global install.
    #
    # So let's just install through trusty Homebrew.
    #
    # We now also install pyenv through Homebrew, so it's nice to be
    # consistent.
    'ruby-build',
    'rbenv',
    # rbenv plugins
    # For the reason this was chosen over alternatives, see
    # https://github.com/maljub01/rbenv-bundle-exec#similar-plugins
    'rbenv-bundle-exec',
    'rbenv-communal-gems',
    'rbenv-default-gems'
  ]
end

###############################################################################
# HOMEBREW FORMULAS AND CASKS
###############################################################################

# Install Emacs with options. Do this before installing the other formulas,
# because the cask formula depends on emacs.
package 'emacs' do
  # The flag --with-glib never actually worked to enable file notifications.
  # However, Emacs 25 (currently in development, hence --devel) supports using
  # kqueue for file notifications. This is detected automatically and it is not
  # necessary to pass any flags.
  options '--devel --with-cocoa --with-gnutls'
end
execute "Link 'Emacs.app' to '/Applications'" do
  command %w(brew linkapps emacs)
  creates '/Applications/Emacs.app'
end

# git-grep PCRE. Do this before installing other formulas in
# case there is a dependency on git.
package 'install custom Git' do
  # Prevent resource cloning from the Homebrew formula
  # Ref: http://tickets.chef.io/browse/CHEF-3694
  package_name 'git'
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

%w(taps formulas casks).each do |entity|
  include_recipe "homebrew::install_#{entity}"
end

# Install X11 software
# Note: XQuartz is installed to /Applications/Utilities/XQuartz.app
homebrew_cask 'xquartz'
# These formulae require XQuartz to be installed first
package 'xclip'
homebrew_cask 'inkscape'

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
  install_dir = "#{node['macos_setup']['home']}/Library/Widgets"

  # This isn't perfect -- the widget will only download and install when the
  # archive file doesn't exist.
  remote_file 'download Deep Sleep dashboard widget' do
    source 'https://github.com/downloads/code2k/Deep-Sleep.wdgt/' +
           archive_name
    checksum 'fa41a926d7c1b6566b074579bdd4c9bc969d348292597ac3064731326efc4207'
    path archive_path
    notifies :run, 'execute[install Deep Sleep dashboard widget]'
  end

  directory install_dir

  execute 'install Deep Sleep dashboard widget' do
    command %W(unzip -o #{archive_path})
    cwd install_dir
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
    command %W(sudo installer -pkg #{pkg_path} -target /)
    not_if { is_installed }
  end
end.call

dmg_package 'Jettison' do
  version = '1.5.2'
  source "http://www.stclairsoft.com/download/Jettison-#{version}.dmg"
  checksum 'c19cc4cc5a58f8694bcc0449e011aaeda5c383f07f32deb0fa4ba86684e337b3'
  volumes_dir "Jettison #{version}"
  action :install
end

directory node['macos_setup']['fonts_dir']

# Ubuntu fonts
#
# The regular Ubuntu font can be installed with SkyFonts, but it doesn't
# include Ubuntu Mono, which we want.
lambda do
  archive_name = 'ubuntu-font-family-0.83.zip'
  archive_path =
    "#{Chef::Config[:file_cache_path]}/#{archive_name}"
  install_dir = "#{node['macos_setup']['fonts_dir']}/Ubuntu"

  remote_file 'download Ubuntu fonts' do
    source "http://font.ubuntu.com/download/#{archive_name}"
    path archive_path
    checksum '456d7d42797febd0d7d4cf1b782a2e03680bb4a5ee43cc9d06bda172bac05b42'
    notifies :run, 'execute[install Ubuntu fonts]'
  end

  directory install_dir

  execute 'install Ubuntu fonts' do
    # Enabled overwrite since this directory is being written to regardless of
    # the version.
    command %W(unzip -o #{archive_path})
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
  path "#{node['macos_setup']['fonts_dir']}/#{filename}"
end

###############################################################################
# PREFERENCES
###############################################################################

# Password-protected screensaver + delay
include_recipe 'mac_os_x::screensaver'

# Turn on the macOS firewall.
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
directory 'create iTerm2 background images directory' do
  path node['macos_setup']['iterm2']['bgs_dir']
  recursive true
end
json_content = JSON.pretty_generate(
  Profiles: node['macos_setup']['iterm2']['profiles'].map do |profile|
    profile = profile.dup
    bg_key = node['macos_setup']['iterm2']['bg_key']
    if profile.key?(bg_key) && Pathname.new(profile[bg_key]).relative?
      base = profile[bg_key]
      cookbook_path = "iterm2-bgs/#{base}"
      install_path =
        "#{node['macos_setup']['iterm2']['bgs_dir']}/#{base}"
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
directory node['macos_setup']['iterm2']['dynamic_profiles_dir']
file 'install iTerm2 dynamic profiles' do
  # This file contains profiles used as parents by the iTerm2/fasd integration.
  # Since iTerm2 loads the list of dynamic profiles alphabetically, we prefix
  # it with a hyphen to ensure it is loaded first.
  # https://iterm2.com/documentation-dynamic-profiles.html
  path node['macos_setup']['iterm2']['dynamic_profiles_dir'] + '/-Personal.json'
  content json_content
end

lambda do
  install_dir = node['macos_setup']['home'] +
                '/Library/Application Support/Karabiner'
  directory install_dir
  cookbook_file 'Karabiner XML settings file' do
    source 'Karabiner_private.xml'
    path "#{install_dir}/private.xml"
  end
end.call

lambda do
  install_dir =
    "#{node['macos_setup']['home']}/Library/Application Support/Quicksilver"
  cookbook_file 'Quicksilver catalog preferences file' do
    source 'Quicksilver-Catalog.plist'
    path "#{install_dir}/Catalog.plist"
  end
end.call

cookbook_file 'Slate preferences file' do
  source 'slate.js'
  path "#{node['macos_setup']['home']}/.slate.js"
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

# Login items
#
# These are controlled by ~/Library/Preferences/com.apple.loginitems.plist,
# which is can be viewed in System Preferences > Users & Group > Current User >
# Login Items. However, this plist is difficult to edit manually because each
# item has an opaque key associated with it. Omitting the opaque key has
# yielded unpredicatable results, and the plist gets rewritten every time it is
# modified through the UI.
#
# Another solution is to create launch agents for each program. This is not as
# well-integrated with the macOS desktop experience, but seems to be the
# cleaner solution in the long run.
#
# See this StackOverflow question for more information:
# http://stackoverflow.com/q/12086638

lambda do
  agents_dir = Pathname.new(node['macos_setup']['home']) +
               'Library/LaunchAgents'
  node['macos_setup']['login_items'].each do |app|
    label = "com.seanfisk.login.#{app.downcase}"
    plist_file "create launch agent to start #{app} at login" do
      # This takes a Pathname for some reason. I'm not complaining, because I
      # love Pathname, but it's just weird.
      file agents_dir + "#{label}.plist"
      content 'Label' => label,
              'ProgramArguments' => %W(/usr/bin/open -a #{app}),
              'RunAtLoad' => true
      action :create
    end
  end
end.call

execute 'invalidate sudo timestamp' do
  # 'sudo -K' will remove the timestamp entirely, which means that sudo will
  # print the initial 'Improper use of the sudo command' warning. Not what we
  # want. 'sudo -k' just invalidates the timestamp without removing it.
  command %w(sudo -k)
  # Kill only if we have sudo privileges. 'sudo -k' is idempotent anyway, but
  # it's nice to see less resources updated when possible.
  #
  # 'sudo -n command' exits with 0 if a password is needed (what?), or the exit
  # code of 'command' if it is able to run it. Hence the unusual guard here: an
  # exit code of 1 indicates sudo privileges, while 0 indicates none.
  not_if %w(sudo -n false)
end
