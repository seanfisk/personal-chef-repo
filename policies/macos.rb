name 'macos'

instance_eval(IO.read("#{File.dirname(__FILE__)}/base.rb"))

# Run macos_setup first so that Homebrew is updated
local_cookbooks %w(macos_setup fasd_iterm2)

# Until a new version is released, this fixes the management of the Cask
# directories.
cookbook 'homebrew',
         github: 'chef-cookbooks/homebrew',
         branch: '87a4a2f2a012128e6ca95197744ee571a31a577e'
