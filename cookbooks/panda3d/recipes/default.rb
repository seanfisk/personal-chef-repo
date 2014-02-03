# -*- coding: utf-8 -*-
#
# Cookbook Name:: panda3d
# Recipe:: default
#
# Copyright 2014, Sean Fisk
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

include_recipe 'dmg'

PANDA3D_VERSION = '1.8.1'
dmg_package 'Panda3D' do
  source "http://www.panda3d.org/download/panda3d-#{PANDA3D_VERSION}" +
    "/Panda3D-#{PANDA3D_VERSION}.dmg"
  checksum '98ac480321c32040a87778c80e7df000100fd2796a1bfa59eba928eed8d2678a'
  type 'mpkg'
  package_id 'org.panda3d.panda3d.base.pkg'
  action :install
end

# Using Panda3D may or may not also require installing NVIDIA's Cg toolkit
# <https://developer.nvidia.com/cg-toolkit>. Unfortunately, it uses a
# .app-based installer that just runs a shell script with a tarball in the
# background. In addition, since it might not be used on every machine, we'll
# avoid automating it for now. But it at least deserves mention here.
