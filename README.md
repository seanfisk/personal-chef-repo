# Mac OS X Chef Configuration

[![Build Status](https://travis-ci.org/seanfisk/macosx-chef-repo.png)](https://travis-ci.org/seanfisk/macosx-chef-repo)

Throughout the instructions, `NODE_NAME` will used as the machine's node name, and should be substituted appropriately.

## Installing

1. First, install the Chef client using the [full-stack installer][chef_install].
1. Since we probably don't have `git` yet, download this repository as a tarball:

        curl --location https://github.com/seanfisk/macosx-chef-repo/archive/master.tar.gz | tar -xz
        mv macosx-chef-repo-master macosx-chef-repo

1. If we do have git, go ahead and clone it:

        git clone git@github.com:seanfisk/macosx-chef-repo.git

1. Go into the repo directory. All following commands should be run from here.

        cd macosx-chef-repo

1. Next, set up the Chef client configuration. This allows us to authenticate to the Chef server using our "machine" client:

        sudo mkdir /etc/chef
        sudo chown "$USER" /etc/chef
        cp client.rb.sample /etc/chef/client.rb
        # Now edit client.rb according to the instructions.
        "$EDITOR" /etc/chef/client.rb

1. Now copy the validation key over to the chef directory:

        cp ~/Downloads/sean_fisk-validator.pem /etc/chef/validation.pem

1. Run `chef-client` to register the client. The registration will create the file `/etc/chef/client.pem`, which allows the "machine" client to communicate with the chef server:

        chef-client

1. Set up the knife configuration. This allows us to authenticate to the Chef server using our "user" client:

        cp ~/Downloads/seanfisk.pem .chef

    Make sure knife is working by typing the following:

        knife client list

    You should see two entries, `sean_fisk-validator` and `NODE_NAME`.

1. Add the `macbook_setup` cookbook to this node's run list:

        knife node run_list add NODE_NAME macbook_setup

1. Provision the laptop:

        chef-client

That's it!

[chef_install]: http://www.opscode.com/chef/install/

# Generating new keys

If you ever lose the keys, they can be re-generated here:

* [User key](https://www.opscode.com/account/password)
* [Organization key](https://manage.opscode.com/organizations)

Be careful, because after re-generating, all nodes must be updated to use the new keys.

# Why not Chef Solo?

It is definitely possible to manage these recipes with Chef Solo. However, both Josh and Seth's tutorials are focused around Hosted Chef. In addition, Berkshelf works a bit better with Hosted Chef, as cookbooks only need to be uploaded initially and then for upgrades. It would be necessary to vendor the Berkshelf cookbooks each time for use with Chef Solo. This is all possible, and shouldn't be too difficult, but it's just not how I decided to do it.

# References

* Josh Timberman
    * [OS X Workstation Management With Chef](http://jtimberman.housepub.org/blog/2012/07/29/os-x-workstation-management-with-chef/)
    * [Update to Managing My Workstations](http://jtimberman.housepub.org/blog/2011/09/04/update-to-managing-my-workstations/)
    * [My Workstations With Chef](http://jtimberman.housepub.org/blog/2011/04/03/managing-my-workstations-with-chef/)
* Seth Vargo
    * [Provision Your Laptop With Chef: Part 1](http://technology.customink.com/blog/2012/05/28/provision-your-laptop-with-chef-part-1/)
    * [Provision Your Laptop With Chef: Part 2](http://technology.customink.com/blog/2012/07/30/provision-your-laptop-with-chef-part-2/)
* Mike English
    * [Simplifying Chef Solo Cookbook Management with Berkshelf](http://spin.atomicobject.com/2013/01/03/berks-simplifying-chef-solo-cookbook-management-with-berkshelf/)
* [Berkshelf](http://berkshelf.com/)
