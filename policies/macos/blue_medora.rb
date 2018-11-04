require_relative 'base'

name 'blue_medora'

load

default['macos_setup']['ruby_manager'] = 'rvm'
default['macos_setup']['extra_casks'] = [
  'firefoxdeveloperedition',
  'intellij-idea',
  'jd-gui', # Java decompiler
  'jetbrains-toolbox',
  'slack',
  'vmware-remote-console',
]
default['macos_setup']['extra_login_items'] = %w(
  Dash
  Emacs
  FirefoxDeveloperEdition
  Slack
)
