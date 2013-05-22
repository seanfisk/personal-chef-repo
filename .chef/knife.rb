current_dir = File.dirname(__FILE__)
log_level                :debug
log_location             STDOUT
node_name                "seanfisk"
client_key               "#{current_dir}/seanfisk.pem"
validation_client_name   "sean_fisk-validator"
validation_key           "#{current_dir}/sean_fisk-validator.pem"
chef_server_url          "https://api.opscode.com/organizations/sean_fisk"
cache_type               'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
cookbook_path            ["#{current_dir}/../cookbooks"]
