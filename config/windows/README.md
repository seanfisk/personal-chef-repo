# Windows Chef Configuration

Throughout the instructions, `NODE_NAME` will used as the machine's node name, and should be substituted appropriately. All commands should be run using Windows PowerShell, not `cmd.exe`.

1. Access the machine you'd like to provision, hereby referred to as the *node*. We will go through a manual boostrap here. While a node can be bootstrapped from an administrator's workstation, that requires the node to have Windows Remote Management (WinRM) configured and running, and that is a little overkill for the bootstrap only. Instead, we manually perform the steps that a boostrap would do (with some modifications).

1. Install the Chef client using the [full-stack installer](http://www.opscode.com/chef/install/).

    On Windows, the installer creates two directories in the root (`C:`):

    * `C:\opscode\chef` -- contains the Chef software itself
    * `C:\chef` -- configuration for Chef

    We are primarily interested in the latter, as it is the configuration we will be modifying.

1. Set up the Chef client configuration. This allows us to authenticate to the Chef server using our *machine* client:

        Invoke-WebRequest https://raw.githubusercontent.com/seanfisk/personal-chef-repo/master/config/windows/client.rb.sample -OutFile C:\chef\client.rb

1. Now edit `client.rb` according to the instructions. Note that WordPad (`write.exe`) is used because it supports UNIX-style line endings.

        &$env:WINDIR\System32\write.exe C:\chef\client.rb

1. Copy the validation key from an existing Cheffed machine or generate a new one and download it to this machine. Move the validation key over to the `C:\chef` directory:

        cp /path/to/sean_fisk-validator.pem C:\chef\validation.pem

1. Run `chef-client` to register the node with our hosted Chef server. The registration will create the file `C:\chef\client.pem`, which allows the *machine* client to communicate with the chef server:

        chef-client

1. At this point, the node is registered and is ready to provision. However, we need to add cookbooks to this node's `run_list`. *From an administrator workstation*, run the following command. If you do not yet have an administrator workstation (i.e., this is the only workstation you have), read the section on setting up an administrator workstation in the main README and return here when finished.

        knife node run_list add NODE_NAME windows_setup

    This command registers the `windows_setup` cookbook to be run when provisioning takes place.

1. Now provision the node with the modified `run_list`:

        chef-client

That's it!
