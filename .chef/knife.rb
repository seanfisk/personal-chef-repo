# -*- coding: utf-8; -*-

# Knife configuration file
#
# For a full list of options, see
# <https://docs.chef.io/config_rb_knife.html>.

current_dir = File.dirname(__FILE__)

chef_server_url 'https://api.opscode.com/organizations/sean_fisk'
client_key "#{current_dir}/seanfisk.pem"
cookbook_copyright 'Sean Fisk'
cookbook_email 'sean@seanfisk.com'
cookbook_license 'apachev2'
cookbook_path ["#{current_dir}/../cookbooks"]
# 'node_name' should correspond to the Hosted Chef username. That's because
# 'node_name' actually specifies the client name, and we want to log in with
# our 'user' client, not our 'machine' client.
node_name 'seanfisk'
syntax_check_cache_path "#{ENV['HOME']}/.chef/syntaxcache"
validation_client_name 'sean_fisk-validator'
