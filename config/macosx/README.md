# Mac OS X Chef Configuration

Throughout the instructions, `NODE_NAME` will used as the machine's node name, and should be substituted appropriately.

1. Access the machine you'd like to provision, hereby referred to as the *node*. We will go through a manual boostrap here. While a node can be bootstrapped from an administrator's workstation, that requires the node to have a running SSH server, which is probably overkill for one-off personal machines. Instead, we manually perform the steps that a boostrap would do (with some modifications).

1. Install the Chef client using the [full-stack installer](https://www.chef.io/download-chef-client/).

1. Create the Chef configuration directory. We change the owner to our user so that we can provision mostly under our standard user. This works well with Mac OS X because most operations don't require root, including installing to `/Applications` and installing [Homebrew](http://brew.sh/) packages.

        sudo mkdir /etc/chef
        sudo chown "$USER" /etc/chef

1. Set up the Chef client configuration. This allows us to authenticate to the Chef server using our *machine* client:

        curl https://raw.githubusercontent.com/seanfisk/personal-chef-repo/master/config/macosx/client.rb.sample > /etc/chef/client.rb

1. Now edit `client.rb` according to the instructions.

        "$EDITOR" /etc/chef/client.rb

1. Copy the validation key from an existing Cheffed machine or generate a new one and download it to this machine. Move the validation key over to the `/etc/chef` directory:

        cp /path/to/sean_fisk-validator.pem /etc/chef/validation.pem

1. Run `chef-client` to register the node with our hosted Chef server. The registration will create the file `/etc/chef/client.pem`, which allows the *machine* client to communicate with the chef server:

        chef-client

1. At this point, the node is registered and is ready to provision. However, we need to add cookbooks to this node's `run_list`. *From an administrator workstation*, run the following command. If you do not yet have an administrator workstation (i.e., this is the only workstation you have), read the section on setting up an administrator workstation in the main README and return here when finished.

        knife node run_list add NODE_NAME macosx_setup

    This command registers the `macosx_setup` cookbook to be run when provisioning takes place.

1. Now provision the node with the modified `run_list`:

        chef-client

That's it!
