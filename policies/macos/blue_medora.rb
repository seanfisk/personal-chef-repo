require_relative 'base'

name 'blue_medora'

load

default['macos_setup']['ruby_manager'] = 'rvm'
default['macos_setup']['extra_formulas'] = [
  'aws-shell',
  'pgcli'
]
default['macos_setup']['extra_casks'] = [
  'dbeaver-enterprise',
  'docker', # This is Docker for Mac, which we use for Code Climate CLI
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
default['macos_setup']['extra_login_items'] =
  %w(Emacs FirefoxDeveloperEdition Slack)
