COOKBOOKS = %w(fasd_iterm2 osx_setup).freeze

name 'osx'
run_list COOKBOOKS
default_source :community
COOKBOOKS.each do |cookbook|
  cookbook cookbook, path: "../cookbooks/#{cookbook}"
end
# Until a new version is released, this fixes the management of the Cask
# directories.
cookbook 'homebrew',
         github: 'chef-cookbooks/homebrew',
         branch: '87a4a2f2a012128e6ca95197744ee571a31a577e'
