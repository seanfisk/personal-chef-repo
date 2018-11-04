require_relative '../base'

def load(extra: [])
  # Run macos_setup first so that Homebrew is updated
  local_cookbooks(%w(macos_setup fasd_iterm2) + extra)
end
