# coding: utf-8
#
# Cookbook:: macos_setup
# Recipe:: default
#
# Copyright:: 2018, Sean Fisk
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

Chef::Application.fatal!(
  'This cookbook must be run as root!'
) unless Process.uid == 0

require 'etc'
require 'json'
require 'pathname'

# Including this causes Homebrew to install if not already installed and to run
# `brew update' if already installed.
include_recipe 'homebrew'

###############################################################################
# HOMEBREW FORMULAS AND CASKS
###############################################################################

# TODO: Don't tap this in my personal policy
homebrew_tap 'Install Blue Medora engineering tap' do
  tap_name 'BlueMedora/engineering'
  url 'git@github.com:BlueMedora/homebrew-engineering.git'
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
  options '--with-pinentry'
end

# Install emacs-mac as my Emacs for use with Spacemacs
#
# Here are the differences from vanilla Emacs:
# https://bitbucket.org/mituharu/emacs-mac/src/f3402395995bf70e50d6e65f841e44d5f9b4603c/README-mac?at=master&fileviewer=file-view-default#README-mac-148
package 'emacs-mac' do
  options '--with-spacemacs-icon'
end

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
# SHELLS
###############################################################################

lambda do
  brew_bin = Pathname.new(
    shell_out!(
      'brew', '--prefix', user: node['macos_setup']['user']
    ).stdout.rstrip
  ) + 'bin'
  etc_shells_path = Pathname.new(node['macos_setup']['etc_shells'])

  # Add the latest Bash and Zsh as possible login shells. Do this after
  # Homebrew installation so that the shell executables are present.
  node['macos_setup']['shells'].each do |shell|
    shell_path = (brew_bin + shell).to_s
    # First, add shell to shells config file so it is recognized as a valid
    # user shell.
    ruby_block "add #{shell_path} to #{node['macos_setup']['etc_shells']}" do
      block do
        etc_shells_path.open('a') do |f|
          f << shell_path << "\n"
        end
      end
      not_if do
        # Don't execute if this shell is already in the shells config file.
        # Open a new file each time to reset the enumerator, and just in case
        # these are executed in parallel.
        etc_shells_path.each_line.any? do |line|
          line.include?(shell_path)
        end
      end
    end
  end

  # Then, set Zsh as the standard user's shell.
  lambda do
    shell_path = brew_bin + 'zsh'
    execute "set #{shell_path} as default shell" do
      command %W(chsh -s #{shell_path} #{node['macos_setup']['user']})
      not_if { Etc.getpwnam(node['macos_setup']['user']).shell == shell_path.to_s }
    end
  end.call
end.call

ruby_block 'fix the zsh startup file that path_helper uses' do
  # macOS has a program called path_helper that allows paths to be easily set
  # for multiple shells. For bash (and other shells), it works great because it
  # is called /etc/profile which is executed only for login shells. However,
  # with zsh, path_helper is run from /etc/zshenv *instead of* /etc/zprofile
  # like it should be. This fixes Apple's mistake.
  #
  # See this link for more information:
  # <https://github.com/sorin-ionescu/prezto/issues/381>
  block do
    File.rename('/etc/zshenv', '/etc/zprofile')
  end
  only_if { File.exist?('/etc/zshenv') }
end

###############################################################################
# CUSTOM INSTALLS
###############################################################################

directory node['macos_setup']['fonts_dir'] do
  owner node['macos_setup']['user']
end

# Ubuntu fonts
lambda do
  archive_name = 'fad7939b-ubuntu-font-family-0.83.zip'
  archive_path =
    "#{Chef::Config[:file_cache_path]}/#{archive_name}"
  install_dir = "#{node['macos_setup']['fonts_dir']}/Ubuntu"

  remote_file 'download Ubuntu fonts' do
    source "https://assets.ubuntu.com/v1/#{archive_name}"
    owner node['macos_setup']['user']
    path archive_path
    checksum '456d7d42797febd0d7d4cf1b782a2e03680bb4a5ee43cc9d06bda172bac05b42'
    notifies :run, 'execute[install Ubuntu fonts]'
  end

  directory install_dir do
    owner node['macos_setup']['user']
  end

  execute 'install Ubuntu fonts' do
    # Enabled overwrite since this directory is being written to regardless of
    # the version.
    command %W(unzip -o #{archive_path})
    cwd install_dir
    user node['macos_setup']['user']
    action :nothing
  end
end.call

remote_file 'download Inconsolata font' do
  # This URL seems like one that may be updated with newer versions, so we'll
  # just install the current version if it's not already installed.
  filename = 'Inconsolata.otf'
  source "http://levien.com/type/myfonts/#{URI.escape(filename)}"
  owner node['macos_setup']['user']
  path "#{node['macos_setup']['fonts_dir']}/#{filename}"
end

remote_file 'download Inconsolata for Powerline font' do
  filename = 'Inconsolata for Powerline.otf'
  source 'https://github.com/powerline/fonts/raw/master/Inconsolata/' +
         URI.escape(filename)
  owner node['macos_setup']['user']
  path "#{node['macos_setup']['fonts_dir']}/#{filename}"
end

###############################################################################
# PREFERENCES
###############################################################################

# Write preferences from attributes.
node['macos_setup']['user_defaults'].each do |domain, defaults|
  defaults.each do |key, value|
    macos_userdefaults "#{domain}: set #{key} → #{value}" do
      domain domain
      key key
      value value
      user node['macos_setup']['user']
    end
  end
end

# iTerm2
#
# There is a Chef cookbook for iterm2, but we've chosen to install using
# Homebrew Cask. The iterm2 cookbook can install tmux integration, but it's
# apparently spotty, and I haven't wanted tmux integration anyway. It also
# raises an annoying error because it looks for the plist in its own cookbook.
#
# Install background images.
lambda do
  directory 'create iTerm2 background images directory' do
    path node['macos_setup']['iterm2']['bgs_dir']
    recursive true
    owner node['macos_setup']['user']
  end
  json_content = JSON.pretty_generate(
    Profiles: node['macos_setup']['iterm2']['profiles'].map do |profile|
      profile = profile.dup
      bg_key = node['macos_setup']['iterm2']['bg_key']
      base = profile[bg_key]
      if base && Pathname.new(base).relative?
        install_path = "#{node['macos_setup']['iterm2']['bgs_dir']}/#{base}"
        profile[bg_key] = install_path
        cookbook_file "install iTerm2 background '#{base}'" do
          source "iterm2-bgs/#{base}"
          path install_path
        end
      end
      profile
    end
  )
  # Install dynamic profiles.
  directory node['macos_setup']['iterm2']['dynamic_profiles_dir'] do
    owner node['macos_setup']['user']
  end
  file 'install iTerm2 dynamic profiles' do
    # This file contains profiles used as parents by the iTerm2/fasd integration.
    # Since iTerm2 loads the list of dynamic profiles alphabetically, we prefix
    # it with a hyphen to ensure it is loaded first.
    # https://iterm2.com/documentation-dynamic-profiles.html
    path node['macos_setup']['iterm2']['dynamic_profiles_dir'] + '/-Personal.json'
    content json_content
    owner node['macos_setup']['user']
  end
end.call

lambda do
  install_dir =
    "#{node['macos_setup']['home']}/Library/Application Support/Quicksilver"
  cookbook_file 'Quicksilver catalog preferences file' do
    source 'Quicksilver-Catalog.plist'
    path "#{install_dir}/Catalog.plist"
    owner node['macos_setup']['user']
  end
end.call

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
  install_dir = "#{node['macos_setup']['home']}/Library/LaunchAgents"
  directory install_dir do
    owner node['macos_setup']['user']
  end

  node['macos_setup']['login_items'].each do |app|
    launchd "create launch agent to start #{app} at login" do
      label = "com.seanfisk.login.#{app.downcase}"
      label label
      mode '600'
      owner node['macos_setup']['user']
      # This resource doesn't have explicit support for user launch agents, so
      # we have to construct our own path.
      path "#{install_dir}/#{label}.plist"
      session_type 'user' # Not sure if this is necessary
      type 'agent'
      program_arguments ['/usr/bin/open', '-a', app]
      run_at_load true
    end
  end
end.call

# Karabiner Elements
# See https://pqrs.org/osx/karabiner/json.html
# We declare it in Ruby instead of having a separate JSON file so that we can use comments (yay, comments!)
# Easily grab this from the current value with this little snippet:
#
#     ruby -e "require 'json'; pp JSON.load(File.open(File.expand_path('~/.config/karabiner/karabiner.json')))"
#

lambda do
  config_dir = "#{node['macos_setup']['home']}/.config/karabiner"
  directory config_dir do
    owner node['macos_setup']['user']
  end
  json_content = JSON.pretty_generate(
    { "profiles" =>
      [
        { "name" => "Default",
          "complex_modifications" =>
          { "rules" =>
            [{ "description" => "Pressing spacebar inserts space. Holding spacebar holds control.",
               "manipulators"=>
               [{ "from" => {"key_code"=>"spacebar", "modifiers"=>{"optional"=>["any"]}},
                  "to" => [{"key_code"=>"left_control"}],
                  "to_if_alone" => [{ "key_code" => "spacebar" }],
                  "type" => "basic" }]}]},
          "selected" => true
        }
      ]
    }
  )
  file 'install Karabiner Elements config file' do
    path "#{config_dir}/karabiner.json"
    content json_content
    owner node['macos_setup']['user']
  end
end.call

###############################################################################
# BLUE MEDORA
###############################################################################

# TODO: Don't execute this for the personal policy.

# Auto-mount Atlas
# See here for the technique: https://gist.github.com/L422Y/8697518

%w(master nfs).each do |type|
  filename = "auto_#{type}"
  cookbook_file "install #{filename}" do
    mode '0644'
    path "/etc/#{filename}"
    source filename
  end
end

execute 'set default browser to FirefoxDeveloperEdition' do
  desired_default_browser = 'firefoxdeveloperedition'
  # Note: When this is run, it will prompt the user using macOS' GUI to confirm the change.
  command %W(defaultbrowser #{desired_default_browser})
  user node['macos_setup']['user']
  not_if {
    shell_out!(%w(defaultbrowser)).stdout.each_line.any? do |line|
      # The current default browser will have an asterisk next to its name
      line == "* #{desired_default_browser}\n"
    end
  }
end
