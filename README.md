# MacBook Pro Chef Configuration

## Installing

* First, install the Chef client using the [full-stack installer][chef_install].
* Since we probably don't have `git` yet, download this repository as a tarball:

        curl --location https://github.com/seanfisk/macbook-chef-repo/archive/master.tar.gz | tar -xz
        mv macbook-chef-repo-master macbook-chef-repo

* If we do have git, go ahead and clone it:

        git clone git@github.com:seanfisk/macbook-chef-repo.git

* Next, we need to put the keys in place. These can be transferred in different ways, but let's just assume they are placed in the directory above the repository:

        cp seanfisk.pem macbook-chef-repo/.chef/seanfisk.pem
        cp sean_fisk-validator.pem /etc/chef/validation.pem

* Copy the client configuration to the correct place:

        cp macbook-chef-repo/.chef/client.rb /etc/chef

* Add the main recipe to the run_list (this may be fixed later by roles):

        knife node run_list add NAME_OF_NODE macbook_setup

  The name of the node may be found from `knife node list`.

* Provision the server:

        chef-client

That's it!

[chef_install]: http://www.opscode.com/chef/install/

# References

* <http://jtimberman.housepub.org/blog/2012/07/29/os-x-workstation-management-with-chef/>
* <http://jtimberman.housepub.org/blog/2011/09/04/update-to-managing-my-workstations/>
* <http://jtimberman.housepub.org/blog/2011/04/03/managing-my-workstations-with-chef/>
* <http://technology.customink.com/blog/2012/05/28/provision-your-laptop-with-chef-part-1/>
* <http://technology.customink.com/blog/2012/07/30/provision-your-laptop-with-chef-part-2/>
* <http://spin.atomicobject.com/2013/01/03/berks-simplifying-chef-solo-cookbook-management-with-berkshelf/>
* <http://berkshelf.com/>
