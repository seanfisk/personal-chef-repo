# -*- coding: utf-8 -*-
#
# Cookbook Name:: mactex
# Recipe:: default
#
# Copyright 2014, Sean Fisk
#
# Licensed under the Apache License, Version 2.0 (the "License"),
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'mixlib/shellout'

pkgutil_proc = Mixlib::ShellOut.new('pkgutil', '--pkgs=org.tug.mactex.texlive2013')
pkgutil_proc.run_command
MACTEX_IS_INSTALLED = pkgutil_proc.exitstatus == 0

PKG_CACHE_PATH = "#{Chef::Config[:file_cache_path]}/MacTeX.pkg"

# First, download the file.
remote_file 'download MacTeX pkg' do
  source 'http://mirror.ctan.org/systems/mac/mactex/MacTeX.pkg'
  path PKG_CACHE_PATH
  checksum '3fb0df81bc20725aa3424c33f2d8d45d9490e15af943fc5080e6e4d91e2c77c2'
  # Don't bother downloading the file if MacTeX is already installed. Since the
  # download is so large, this allows us to delete the pkg file from the cache
  # once MacTeX is already installed and still be sure that the cookbook is
  # going to handle it correctly.
  not_if { MACTEX_IS_INSTALLED }
end

# Now install.
execute 'install MacTeX' do
  # rubocop:disable LineLength
  #
  # With some help from:
  # - https://github.com/opscode-cookbooks/dmg/blob/master/providers/package.rb
  # - https://github.com/mattdbridges/chef-osx_pkg/blob/master/providers/package.rb
  #
  # rubocop:enable LineLength
  command "sudo installer -pkg '#{PKG_CACHE_PATH}' -target /"
  not_if { MACTEX_IS_INSTALLED }
end

# rubocop:disable LineLength
#
# Deploy workaround for lualatex's font database. See:
# - http://tex.stackexchange.com/questions/140840/lualatex-luaotfload-broke-after-upgrading-to-mavericks
# - https://github.com/lualatex/luaotfload/issues/139

BLACKLIST_FILE = '/usr/local/texlive/2013/texmf-dist/tex/luatex/luaotfload/luaotfload-blacklist.cnf'
BLACKLIST_APPEND_CONTENTS =
  '% Causes segfaults, see http://tex.stackexchange.com/questions/140840/lualatex-luaotfload-broke-after-upgrading-to-mavericks\\n' +
  'Silom.ttf\\n' +
  'Skia.ttf'

# rubocop:enable LineLength

execute 'add font to blacklist' do
  # Yucky quoting. See below for why the better solution doesn't work.
  command "sudo bash -c \"echo -e '#{BLACKLIST_APPEND_CONTENTS}'>> '#{BLACKLIST_FILE}'\"" # rubocop:disable LineLength
  not_if do
    # Don't execute if we've already added blacklist. We just check for
    # 'Skia.ttf'.
    File.open(BLACKLIST_FILE).lines.any? do
      |line| line.include?('Skia.ttf')
    end
  end
end

# To allow the font blacklisting to take effect, run:
#
#     mkluatexfontdb --force --verbose=10 --update
#
# Note that this WILL NOT WORK, as it ignores blacklisted fonts for some
# reason:
#
#     luaotfload-tool --force --verbose=10 --update
#
# Not sure why it does that but it's really confusing and inconvenient.

# Unfortunately, this doesn't work, because there's no way that I know of to
# execute this block using sudo.
#
# ruby_block 'add font to blacklist' do
#   block do
#     File.open(BLACKLIST_FILE, 'a') do |file|
#       file.puts('% Causes segfault, see http://tex.stackexchange.com/questions/140840/lualatex-luaotfload-broke-after-upgrading-to-mavericks') # rubocop:disable LineLength
#       file.puts(BLACKLIST_FONT)
#     end
#   end
# end
