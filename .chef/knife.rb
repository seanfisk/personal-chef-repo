# Sample knife configuration file
#
# For a full list of options, see <http://docs.opscode.com/config_rb_knife.html>.

current_dir = File.dirname(__FILE__)

cache_options({:path => "#{current_dir}/cache/checksums", :skip_expires => true})
chef_server_url        'https://api.opscode.com/organizations/sean_fisk'
client_key             "#{current_dir}/seanfisk.pem"
cookbook_copyright     'Sean Fisk'
cookbook_email         'sean@seanfisk.com'
cookbook_license       'apachev2'
cookbook_path          ["#{current_dir}/../cookbooks"]
# node_name should correspond to the Opscode hosted chef username. That's because node_name actually specifies the client name, and we want to log in with our "user" client, not our "machine" client.
node_name              'seanfisk'
validation_client_name 'sean_fisk-validator'
