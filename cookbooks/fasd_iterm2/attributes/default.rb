#
# Copyright:: 2018, Sean Fisk
#
# Licensed under the Apache License, Version 2.0 (the "License");
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

default['fasd_iterm2'].tap do |o|
  # See macos_setup for details
  o['user'] = ENV['SUDO_USER']
  o['repo_url'] = 'https://github.com/seanfisk/fasd-iterm2-profiles.git'
  o['repo_path'] = "#{Chef::Config[:file_cache_path]}/fasd-iterm2-profiles"
end
