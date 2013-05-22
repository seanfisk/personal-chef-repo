log_level        :debug
log_location     STDOUT
chef_server_url  'https://api.opscode.com/organizations/sean_fisk'
validation_client_name 'sean_fisk-validator'

# make runnable by standard user
base_dir = '/Users/sean/.chef'
checksum_path           "#{base_dir}/checksum"
file_cache_path         "#{base_dir}/cache"
file_backup_path        "#{base_dir}/backup"
cache_options({:path => "#{base_dir}/cache/checksums", :skip_expires => true})
