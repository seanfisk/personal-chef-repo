# coding: UTF-8
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

MACTEX_IS_INSTALLED = system('pkgutil --pkgs=org.tug.mactex.texlive2013')

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
