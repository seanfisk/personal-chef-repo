#
# Cookbook Name:: macbook_setup
# Recipe:: default
#
# Copyright (C) 2013 Sean Fisk
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'iterm2'

include_recipe 'dmg'
include_recipe 'mac_os_x'

dmg_package 'Adium' do
  source 'http://download.adium.im/Adium_1.5.6.dmg'
  checksum 'd5f580b7db57348c31f8e0f18691d7758a65ad61471bf984955360f91b21edb8'
  volumes_dir 'Adium 1.5.6'
  action :install
end

dmg_package 'Quicksilver' do
  source 'http://github.qsapp.com/downloads/Quicksilver%201.0.0.dmg'
  checksum '0afb16445d12d7dd641aa8b2694056e319d23f785910a8c7c7de56219db6853c'
  dmg_name 'Quicksilver 1.0.0'
  action :install
  # This should work but it doesn't seem to. So we went with the
  # `not_if' solution below.

  # notifies :create, 'mac_os_x_plist_file[com.blacktree.Quicksilver.plist]'
end

mac_os_x_plist_file 'com.blacktree.Quicksilver.plist' do
  # Create a plist file for Quicksilver specifying the hotkey, among
  # other things. Unfortunately, this doesn't avoid going through the
  # setup assistant, but it helps out a bit.

  # Don't overwrite the file if it already exists.
  not_if {File.exists?("#{ENV['HOME']}/Library/Preferences/#{source}")}
end

dmg_package 'Emacs' do
  source 'http://emacsformacosx.com/emacs-builds/Emacs-24.3-universal-10.6.8.dmg'
  checksum '92b3a6dd0a32b432f45ea925cfa34834c9ac9f7f0384c38775f6760f1e89365a'
  action :install
end

dmg_package 'Google Chrome' do
  source 'https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg'
  checksum '0e43d17aa2fe454e890bd58313f567de07e2343c0d447ef5496dbda9ff45e64d'
  dmg_name 'googlechrome'
  action :install
end

dmg_package 'Skim' do
  source 'http://downloads.sourceforge.net/project/skim-app/Skim/Skim-1.4.3/Skim-1.4.3.dmg'
  checksum 'bc01dffe6f471fffc531222a56ab27f553ce42b91c800fe53f3770926feda809'
  action :install
end
