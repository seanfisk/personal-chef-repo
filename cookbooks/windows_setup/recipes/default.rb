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

include_recipe 'chocolatey'

node['windows_setup']['packages'].each do |pkg_name|
  chocolatey pkg_name
end

# Allow running of local PowerShell scripts (default policy is Restricted).
DESIRED_POLICY = 'RemoteSigned'
powershell_script 'set execution policy' do
  code "Set-ExecutionPolicy #{DESIRED_POLICY}"
  guard_interpreter :powershell_script
  not_if "$(Get-ExecutionPolicy) -eq '#{DESIRED_POLICY}'"
end