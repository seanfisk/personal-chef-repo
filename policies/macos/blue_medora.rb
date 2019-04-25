require_relative 'base'

name 'blue_medora'

load

default['macos_setup']['extra_casks'] = [
  'firefoxdeveloperedition',
  'jd-gui', # Java decompiler
  # When using the JetBrains Toolbox, do not use the intellij-idea or
  # intellij-idea-ce cask. JetBrains Toolbox installs its own versions of
  # IntelliJ to its own location.
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
