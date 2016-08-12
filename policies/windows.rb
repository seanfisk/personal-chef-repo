COOKBOOKS = %w(windows_setup).freeze

name 'windows'
run_list COOKBOOKS
default_source :community
COOKBOOKS.each do |cookbook|
  cookbook cookbook, path: "../cookbooks/#{cookbook}"
end
