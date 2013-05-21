#
# Cookbook Name:: macbook_setup
# Recipe:: default
#
# Copyright (C) 2013 Sean Fisk
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'dmg'

dmg_package 'Adium' do
  source 'http://download.adium.im/Adium_1.5.6.dmg'
  checksum 'd5f580b7db57348c31f8e0f18691d7758a65ad61471bf984955360f91b21edb8'
  volumes_dir 'Adium 1.5.6'
  action :install
end
