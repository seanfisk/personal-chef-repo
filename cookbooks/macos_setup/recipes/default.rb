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
# MAC APP STORE
###############################################################################

# I'd like to use https://github.com/RoboticCheese/mac-app-store-chef, but it doesn't appear to be maintained anymore. Some people are trying, though: https://github.com/RoboticCheese/mac-app-store-chef/pulls
#
# We could write a custom wrapper around mas-cli, but it's probably easier to just use Homebrew Bundle.
#
# TODO: Consider using Homebrew Bundle for everything?

cookbook_file 'install global Brewfile' do
  source 'Brewfile'
  path "#{node['macos_setup']['home']}/.Brewfile"
  owner node['macos_setup']['user']
end

execute 'install dependencies from global Brewfile' do
  command %w(brew bundle install --global)
  user node['macos_setup']['user']
  not_if do
    shell_out(
      %w(brew bundle check --global),
      user: node['macos_setup']['user']
    ).exitstatus == 0
  end
end

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
  only_if { ::File.exist?('/etc/zshenv') }
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

# The idempotency check for this is not working in regular usage because grep is interpreting it as an option.
# See https://github.com/chef/chef/blob/c7d9809deee1f5ebc5c7ba8ec5343f026d60698c/lib/chef/resource/macos_userdefaults.rb#L79
# TODO Fix this upstream
lambda do
  domain = 'org.macosforge.xquartz.X11'
  key = 'depth'
  value = '-1' # This means "Use colors from display"
  macos_userdefaults "#{domain}: set #{key} → #{value}" do
    domain domain
    key key
    value value
    user node['macos_setup']['user']
    not_if { shell_out!(%W(defaults read #{domain} #{key}), user: node['macos_setup']['user']).stdout.rstrip == value }
  end
end.call

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
    'profiles' => [
      { 'name' => 'Default',
        'selected' => true,
        # Swap Caps Lock and Control
        'simple_modifications' => %w(left_control caps_lock).permutation.map do |keys|
          { 'from' => { 'key_code' => keys.first },
            'to' => { 'key_code' => keys.last } }
        end,
        'complex_modifications' => {
          'rules' => [
            { 'description' => 'Pressing spacebar inserts space. Holding spacebar holds control.',
              'manipulators' => [
                { 'from' => { 'key_code' => 'spacebar', 'modifiers' => { 'optional' => ['any'] } },
                  'to' => [{ 'key_code' => 'left_control' }],
                  'to_if_alone' => [{ 'key_code' => 'spacebar' }],
                  'type' => 'basic',
                },
              ],
            },
          ],
        },
        'devices' => [
          {
            'identifiers' => {
              'is_keyboard' => true,
              'is_pointing_device' => false,
              # Filco Majestouch 2
              'product_id' => 17_733,
              'vendor_id' => 1_241,
            },
            # Swap Option and Command
            'simple_modifications' => %w(left right).flat_map do |side|
              %w(option command).permutation.map do |from, to|
                { 'from' => { 'key_code' => "#{side}_#{from}" },
                  'to' => { 'key_code' => "#{side}_#{to}" } }
              end
            end,
          },
        ],
      },
    ]
  )
  file 'install Karabiner Elements config file' do
    path "#{config_dir}/karabiner.json"
    content json_content
    owner node['macos_setup']['user']
  end
end.call

# Wunderlist doesn't support custom backgrounds, but there is a way around this: https://www.quora.com/How-can-I-add-my-own-background-into-wunderlist
# Replace Wunderlist's hideous orange gradient background with a cool picture of Bora Bora. Not bothering to replace the thumbnail since I know which one it is.
cookbook_file 'install Wunderlist custom background' do
  source 'wunderlist-background.jpg'
  path '/Applications/Wunderlist.app/Contents/Resources/wlbackground16.jpg'
end

lambda do
  hammerspoon_dir = "#{node['macos_setup']['home']}/.hammerspoon"
  directory hammerspoon_dir do
    owner node['macos_setup']['user']
  end
  cookbook_file 'install Hammerspoon config' do
    source 'hammerspoon-init.lua'
    path "#{hammerspoon_dir}/init.lua"
    owner node['macos_setup']['user']
  end
end.call

###############################################################################
# CUSTOM INSTALLS
###############################################################################

# Network Link Conditioner; see https://stackoverflow.com/a/9659486 for the download link
# Since this is an Apple Developer download, we've vendored it into our cookbook.

# remote_directory can be used to copy a directory tree, but it can't preserve the original mode with an idempotency check.
# We therefore have this really weird setup where we have files separated by their desired mode.

%w(644 755).each do |mode|
  remote_directory "install Network Link Conditioner files with mode #{mode}" do
    source "Network Link Conditioner/#{mode}"
    # Although it's possible to install to ~/Library/PreferencePanes and Network Link Conditioner *seems* to work if we do, it doesn't show up in System Preferences and must be launched via the "open" utility. So, install to the global location.
    path '/Library/PreferencePanes/Network Link Conditioner.prefPane'
    files_mode mode
  end
end

directory 'create personal bin/ directory' do
  path node['macos_setup']['bin_dir']
  owner node['macos_setup']['user']
end

remote_file "install iTerm2's imgcat script" do
  # Do not include a checksum because we *want* the latest version. This means that Chef will use a conditional GET: https://docs.chef.io/resource_remote_file.html#prevent-re-downloads
  source 'https://www.iterm2.com/utilities/imgcat'
  path "#{node['macos_setup']['bin_dir']}/imgcat"
  owner node['macos_setup']['user']
  mode '0755'
end

lambda do
  software_name = 'Java API Compliance Checker'
  version = '2.4'
  archive_path = "#{Chef::Config[:file_cache_path]}/japi-compliance-checker.tar.gz"
  extract_name = "extract #{software_name} archive"
  prefix = '/usr/local'
  install_name = "install #{software_name} to #{prefix}"

  remote_file "download #{software_name}" do
    source "https://github.com/lvc/japi-compliance-checker/archive/#{version}.tar.gz"
    checksum '0fd8ff8539a6f4a2c30379999befc1f9003fbb513f778b018a722360ab8c2229'
    path archive_path
    notifies :extract, "archive_file[#{extract_name}]"
  end

  archive_file extract_name do
    path archive_path
    extract_to Chef::Config[:file_cache_path]
    notifies :run, "execute[#{install_name}]"
    action :nothing
  end

  execute install_name do
    # The Makefile is broken and should have the 'install' target marked as phony, but doesn't. This causes the target not to run. Just run what it would have executed anyway.
    command %W(perl Makefile.pl -install -prefix #{prefix})
    creates "#{prefix}/japi-compliance-checker"
    cwd "#{Chef::Config[:file_cache_path]}/japi-compliance-checker-#{version}"
    action :nothing
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
  not_if do
    shell_out!(%w(defaultbrowser), user: node['macos_setup']['user']).stdout.each_line.any? do |line|
      # The current default browser will have an asterisk next to its name
      line == "* #{desired_default_browser}\n"
    end
  end
end
