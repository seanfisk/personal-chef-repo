# coding: UTF-8
#
# Cookbook Name:: pythonz
# Recipe:: default
#
# Copyright 2013, Sean Fisk
#
# Licensed under the Apache License, Version 2.0 (the "License")
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

execute 'run pythonz install script' do
  command "./#{node['pythonz']['install_script_name']}"
  cwd Chef::Config[:file_cache_path]
  action :nothing
end

remote_file "#{Chef::Config[:file_cache_path]}/" +
  node['pythonz']['install_script_name'] do
  source node['pythonz']['install_script_url']
  mode '500'

  notifies :run, 'execute[run pythonz install script]'
end
