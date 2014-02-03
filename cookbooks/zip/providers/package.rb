# -*- coding: utf-8 -*-
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

def load_current_resource
  @zippkg = Chef::Resource::ZipPackage.new(new_resource.name)
  @zippkg.app(new_resource.app)
  Chef::Log.debug("Checking for application #{new_resource.app}")
  @zippkg.installed(installed?)
end

action :install do
  unless @zippkg.installed

    zip_file =
      "#{Chef::Config[:file_cache_path]}/#{new_resource.app}.zip"
    # Create with a prefix of `new_resource.name'.
    # Create in directory `Chef::Config[:file_cache_path]'
    tmp_extraction_dir =
      Dir.mktmpdir(new_resource.app, Chef::Config[:file_cache_path])

    remote_file "#{zip_file} - #{@zippkg.name}" do
      path zip_file
      source new_resource.source
      checksum new_resource.checksum if new_resource.checksum
      only_if { new_resource.source }
    end

    execute "unzip #{zip_file}" do
      # We could just unzip directly into the destination directory,
      # but sometimes the zip files have extra junk in them (e.g.,
      # __MAC_OS_X__, .DS_Store, READMEs, etc.). We don't want that
      # junk in our destination directory.
      cwd tmp_extraction_dir
    end

    execute "install #{new_resource.name}" do
      command "cp -R *.app '#{new_resource.destination}'"
      cwd tmp_extraction_dir
      user new_resource.owner if new_resource.owner
    end

    file ("#{new_resource.destination}/#{new_resource.app}.app" +
          "/Contents/MacOS/#{new_resource.app}") do
      mode 0755
      ignore_failure true
    end

    # See <http://acrmp.github.io/foodcritic/#FC017>
    # My state has changed so I'd better notify observers
    new_resource.updated_by_last_action(true)
  end
end

private

def installed?
  if Dir.exists?("#{new_resource.destination}/#{new_resource.app}.app")
    Chef::Log.info 'Already installed; to upgrade, remove '
    "\"#{new_resource.destination}/#{new_resource.app}.app\""
    true
  else
    false
  end
end
