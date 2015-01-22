# -*- coding: utf-8 -*-
#
# Cookbook Name:: windows_setup
# Recipe:: default
#
# Author:: Sean Fisk <sean@seanfisk.com>
# Copyright:: Copyright (c) 2014, Sean Fisk
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

# NOTE: powershell_script doesn't support the 'command' attribute. Argh...!

directory node['windows_setup']['scripts_dir'] do
  recursive true
end
# The 'env' resource works for system environment variables, but apparently not
# for user environment variables. Since this is a per-user scripts directory,
# it makes sense to put in in the user environment variable.
var = 'Path'
scope = 'User'
path = node['windows_setup']['scripts_dir']
get_var_command = (
  "[Environment]::GetEnvironmentVariable('#{var}', '#{scope}')")
powershell_script "add #{path} to the #{scope} #{var}" do
  code "[Environment]::SetEnvironmentVariable('#{var}', "\
       "#{get_var_command} + ';' + '#{path}', '#{scope}')"
  not_if "#{get_var_command}.Split(';') -Contains '#{path}'"
end

# Fails out with insufficient permissions. I guess we'll just assume it exists
# for now.
#
# directory node['windows_setup']['startup_dir'] do
#   recursive true
# end

include_recipe 'chocolatey'

node['windows_setup']['packages'].each do |pkg_name|
  chocolatey pkg_name
end

# Swap Caps Lock and Control using AutoHotKey.
script_base = 'SwapCapsLockControl'
script_name = "#{script_base}.ahk"
script_path = "#{node['windows_setup']['scripts_dir']}\\#{script_name}"
shortcut_path = "#{node['windows_setup']['startup_dir']}\\#{script_base}.lnk"
cookbook_file script_name do
  path script_path
end
windows_shortcut shortcut_path do
  target script_path
  description 'Swap Caps Lock and Control on startup'
end

# Gibo
script_name = 'gibo.bat'
remote_file 'download and install Gibo' do
  # This file will likely change, so don't provide a checksum.
  source 'https://raw.githubusercontent.com/simonwhitaker/gibo/master/' +
    script_name
  path "#{node['windows_setup']['scripts_dir']}\\#{script_name}"
end
