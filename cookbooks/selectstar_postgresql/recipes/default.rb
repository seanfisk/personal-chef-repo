#
# Cookbook:: selectstar_postgresql
# Recipe:: default
# Author:: Sean Fisk <sean@seanfisk.com>
# Copyright:: Copyright (c) 2017, Sean Fisk
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

directory 'create PostgreSQL data directory' do
  path node['selectstar_postgresql']['data_dir']
  recursive true
end

cookbook_file 'create PostgreSQL configuration file' do
  source 'postgresql.conf'
  mode '0600'
  path "#{node['selectstar_postgresql']['data_dir']}/postgresql.conf"
end
