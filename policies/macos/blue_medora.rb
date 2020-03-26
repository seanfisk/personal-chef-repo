# coding: utf-8
require_relative 'base'

name 'blue_medora'

load

default['macos_setup']['extra_formulas'] = %w(
  ex-uno-architect
  ex-uno-diff
  vrops-architect
)
default['macos_setup']['extra_casks'] = [
  'firefoxdeveloperedition',
  'jd-gui', # Java decompiler
  # When using the JetBrains Toolbox, do not use the intellij-idea or
  # intellij-idea-ce cask. JetBrains Toolbox installs its own versions of
  # IntelliJ to its own location.
  'jetbrains-toolbox',
  'slack',
  'vmware-remote-console',
  # There are *plenty* of choices for VNC viewers. They all pretty much work the same.
  #
  # • RealVNC is the original VNC server and viewer, but some versions are proprietary. They also have UI for signing up for a RealVNC account… no thanks.
  # • Chicken hasn't been updated in a while.
  # • I had a good experience with Remmina on GNU/Linux but it isn't easily available for macOS.
  # • This page has convinced me (somewhat simply through its existence) that TurboVNC is better than TigerVNC: https://turbovnc.org/About/TigerVNC
  #
  # Went with TurboVNC for these reasons.
  'turbovnc-viewer',
  'euchre',
  'nsa',
]
default['macos_setup']['extra_login_items'] = %w(
  Dash
  Emacs
  FirefoxDeveloperEdition
  Slack
)
