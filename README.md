# Chef Configurations for Personal Machines

[![Build Status](https://travis-ci.org/seanfisk/personal-chef-repo.png)](https://travis-ci.org/seanfisk/personal-chef-repo)

This repository contains personal configurations for my machines, set up using the [Chef configuration management system][chef].

[chef]: http://www.getchef.com/

Please see the README for one of the configurations for more instructions on how to install:

* [macOS](https://github.com/seanfisk/personal-chef-repo/tree/master/config/macos)
* [Windows](https://github.com/seanfisk/personal-chef-repo/tree/master/config/windows)

## Development

### Shell

All of the shell commands in this guide assume you are running [GNU Bash][] 4.x or [Zsh][] 5.x. Check the version of your current shell with one of the following commands:

```bash
echo $BASH_VERSION
echo $ZSH_VERSION
```

If you are using a different shell, you are on your own.

### Homebrew

[Homebrew][] is used to install some dependencies for the project, so install that now by following the instructions if you do not already have it. After installation, be sure to run the following commands to make sure Homebrew is set up correctly:

    brew update
    brew doctor

### Chef Workstation

**Note:** According to Chef, [Chef Workstation replaces ChefDK](https://www.chef.sh/docs/chef-workstation/about/). ChefDK is still available, but we are using Chef Workstation. Begin by installing it from [Chef's Homebrew tap][]:

    brew cask install chef/chef/chef-workstation

### Ruby

Next, install [rbenv][] if it is not already installed. Then, install [rbenv-chef-workstation][]. Note that at this time of writing, the Homebrew install does not work.

Then, make sure the right Ruby is being used by running the following commands:

```bash
$ rbenv version
chef-workstation (set by /path/to/chef-repo/.ruby-version)
$ rbenv which ruby
/opt/chef-workstation/embedded/bin/ruby
```

### Setting up an administrator workstation

An administrator workstation is used to edit the Chef cookbooks in this repository and to run Knife, the Chef server utility.

1. Clone this repository:

        git clone git@github.com:seanfisk/personal-chef-repo.git chef-repo

1. Go into the repo directory. All following commands should be run from here.

        cd chef-repo

1. Set up the Knife configuration. Copy the *user* key from an existing administrator workstation or generate a new one and download it to this machine. This allows us to authenticate to the Chef server using our *user* client:

        cp /path/to/seanfisk.pem .chef

1. Make sure Knife is working by typing the following:

        knife client list

    You should see an entry named `sean_fisk-validator`. If so, Knife is working properly!

### Testing

Run the following to test:

    bin/thor test:all

## Generating new keys

If you ever lose the keys, they can be re-generated here:

* [User key](https://www.chef.io/account/password)
* [Organization key](https://manage.chef.io/organizations)

Be careful, because after re-generating, all nodes must be updated to use the new keys.

## Why not Chef Solo?

Using Chef Solo essentially requires having a development environment present on the node that needs to be provisioned. While this is something that I typically do eventually, it's nice to be able to provision immediately (like starting a new job) or provision without setting up an environment on a one-off node.

## Ruby version

There are two Rubies that are used for this project: the embedded Ruby used by [Chef Client][] and the Ruby used for development. The development Ruby runs the tasks in the Thorfile, while the embedded Ruby executes the cookbooks. There's no requirement for these to be identical, but it's advantageous to keep them as close as possible because of [Rubocop][]. Rubocop parses the cookbooks as the Ruby under which it is currently running would. Since the cookbooks are ultimately run by Chef Client's embedded Ruby, the Ruby versions should be the same.

You can find the version of the embedded Ruby that Chef Client uses on macOS with the following:

    /opt/chef/embedded/bin/ruby --version

## References

* Josh Timberman
    * [OS X Workstation Management With Chef](http://jtimberman.housepub.org/blog/2012/07/29/os-x-workstation-management-with-chef/)
    * [Update to Managing My Workstations](http://jtimberman.housepub.org/blog/2011/09/04/update-to-managing-my-workstations/)
    * [My Workstations With Chef](http://jtimberman.housepub.org/blog/2011/04/03/managing-my-workstations-with-chef/)
* Seth Vargo
    * [Provision Your Laptop With Chef: Part 1](http://technology.customink.com/blog/2012/05/28/provision-your-laptop-with-chef-part-1/)
    * [Provision Your Laptop With Chef: Part 2](http://technology.customink.com/blog/2012/07/30/provision-your-laptop-with-chef-part-2/)
* Mike English
    * [Simplifying Chef Solo Cookbook Management with Berkshelf](http://spin.atomicobject.com/2013/01/03/berks-simplifying-chef-solo-cookbook-management-with-berkshelf/) [historical, since I don't use Berkshelf anymore]

[Chef Client]: https://docs.chef.io/chef_client.html
[GNU Bash]: https://www.gnu.org/software/bash/
[Homebrew]: https://brew.sh/
[Rubocop]: https://github.com/bbatsov/rubocop
[Zsh]: http://www.zsh.org/
[rbenv]: https://github.com/rbenv/rbenv#installation
[rbenv-chef-workstation]: https://github.com/docwhat/rbenv-chef-workstation#installation
[Chef's Homebrew tap]: https://github.com/chef/homebrew-chef
