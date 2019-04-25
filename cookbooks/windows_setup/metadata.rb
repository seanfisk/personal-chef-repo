name 'windows_setup'
maintainer 'Sean Fisk'
maintainer_email 'sean@seanfisk.com'
source_url 'https://github.com/seanfisk/personal-chef-repo'
issues_url 'https://github.com/seanfisk/personal-chef-repo/issues'
license 'Apache-2.0'
description 'Setup my personal Windows operating system'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'
supports 'windows'
chef_version '~> 14'

depends 'chocolatey', '~> 2.0.1'
depends 'windows', '~> 5.3.0'
