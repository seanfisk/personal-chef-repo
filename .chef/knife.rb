# -*- coding: utf-8; -*-

# Knife configuration file
#
# For a full list of options, see
# <https://docs.chef.io/config_rb_knife.html>.

current_dir = File.dirname(__FILE__)

chef_server_url 'https://api.opscode.com/organizations/ibrahim_ahmed'
client_key "#{current_dir}/atbe.pem"
cookbook_copyright 'Ibrahim Ahmed'
cookbook_email 'ahmedibr@msu.edu'
cookbook_license 'apachev2'
cookbook_path ["#{current_dir}/../cookbooks"]
# 'node_name' should correspond to the Hosted Chef username. That's because
# 'node_name' actually specifies the client name, and we want to log in with
# our 'user' client, not our 'machine' client.
node_name 'atbe'
syntax_check_cache_path "#{ENV['HOME']}/.chef/syntaxcache"
validation_client_name 'ibrahim_ahmed-validator'
