# -*- coding: utf-8 -*-
name 'macos_setup'
maintainer 'Sean Fisk'
maintainer_email 'sean@seanfisk.com'
source_url 'https://github.com/seanfisk/personal-chef-repo'
issues_url 'https://github.com/seanfisk/personal-chef-repo/issues'
license 'Apache 2.0'
description 'Setup my personal macOS operating system'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'mac_os_x'

depends 'dmg', '~> 2.4.0'
depends 'mac_os_x', '~> 1.4.6'
depends 'homebrew', '~> 2.1.0'
depends 'rvm', '~> 0.9.4'
