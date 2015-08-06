# Chef Configurations for Personal Machines

[![Build Status](https://travis-ci.org/seanfisk/personal-chef-repo.png)](https://travis-ci.org/seanfisk/personal-chef-repo)

This repository contains personal configurations for my machines, set up using the [Chef configuration management system][chef].

[chef]: http://www.getchef.com/

Please see the README for one of the configurations for more instructions on how to install:

* [Mac OS X](https://github.com/seanfisk/personal-chef-repo/tree/master/config/osx)
* [Windows](https://github.com/seanfisk/personal-chef-repo/tree/master/config/windows)

## Setting up an Administrator Workstation

An administrator workstation is used to edit the Chef cookbooks in this repository and to run Knife, the Chef server utility. Please see [LearnChef](https://learn.chef.io/legacy/get-started/) for a nice summary and visuals.

1. Clone this repository:

        git clone git@github.com:seanfisk/personal-chef-repo.git chef-repo

1. Go into the repo directory. All following commands should be run from here.

        cd chef-repo

1. Set up the Knife configuration. Copy the *user* key from an existing administrator workstation or generate a new one and download it to this machine. This allows us to authenticate to the Chef server using our *user* client:

        cp /path/to/seanfisk.pem .chef

1. Make sure Knife is working by typing the following:

        knife client list

    You should see an entry named `sean_fisk-validator`. If so, Knife is working properly!

## Generating new keys

If you ever lose the keys, they can be re-generated here:

* [User key](https://www.chef.io/account/password)
* [Organization key](https://manage.chef.io/organizations)

Be careful, because after re-generating, all nodes must be updated to use the new keys.

## Why not Chef Solo?

It is definitely possible to manage these recipes with Chef Solo. However, both Josh and Seth's tutorials are focused around Hosted Chef. In addition, Berkshelf works a bit better with Hosted Chef, as cookbooks only need to be uploaded initially and then for upgrades. It would be necessary to vendor the Berkshelf cookbooks each time for use with Chef Solo. This is all possible, and shouldn't be too difficult, but it's just not how I decided to do it.

## References

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
