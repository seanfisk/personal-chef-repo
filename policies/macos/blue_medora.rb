require_relative 'base'

name 'blue_medora'

load

default['macos_setup']['ruby_manager'] = 'rvm'
default['macos_setup']['extra_casks'] = [
  'dbeaver-enterprise',
  # There are a number of different versions of Eclipse. The eclipse-ide cask,
  # described as 'Eclipse IDE for Eclipse Committers', is actually just the
  # standard package without any extras. This is nice, because extras can
  # always be installed using the Eclipse Marketplace.
  #
  # Using this for browsing DynamoDB using the AWS Toolkit for Eclipse.
  'eclipse-ide',
  'firefoxdeveloperedition',
  'slack'
]
