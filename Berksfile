# -*- mode: ruby; coding: utf-8; -*-

source 'https://supermarket.chef.io'

group :osx do
  cookbook 'dmg', '~> 2.4.0'
  cookbook 'mac_os_x', '~> 1.4.6'
  # cookbook 'homebrew', '~> 2.1.0'
  # Until a new version is released, this fixes the management of the Cask
  # directories.
  cookbook 'homebrew',
           git: 'https://github.com/chef-cookbooks/homebrew.git',
           branch: '87a4a2f2a012128e6ca95197744ee571a31a577e'
end

group :windows do
  cookbook 'chocolatey', '~> 1.0.0'
  cookbook 'windows', '~> 1.43.0'
end
