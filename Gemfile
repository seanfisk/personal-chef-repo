# -*- mode: ruby; coding: utf-8; -*-

source 'https://rubygems.org'

gem 'thor', '~> 0.20.0'
gem 'travis', '~> 1.8', '>= 1.8.8'
# For printing fancy pass/fail message :)
gem 'artii', '~> 2.1', '>= 2.1.2'

# These are included in the Chef DK, but we need them declared here for them to
# be loaded into our Bundler environment. They can be different versions than
# those gems included with the Chef DK, in which case they'll be installed as
# normal upon 'bundle install'.
gem 'foodcritic', '~> 13.1', '>= 13.1.1'
gem 'cookstyle', '~> 2.1'

# This version must exactly match the version returned by this command:
#
#     /opt/chefdk/bin/chef-client --version
#
# Otherwise, problems ensue: https://github.com/chef/chef-dk/issues/1526
gem 'chef', '= 13.8.5'
