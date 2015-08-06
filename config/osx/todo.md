High Priority
-------------

* Google Talk plugin (also note that this needs to be blocked in Firefox, as it forces a transition to the discrete GPU even when the plugin really isn't being used [i.e., not in hangouts]).
* `sudo` prompts in various resources are not showing, and script is hanging waiting for them.
* Use PlistBuddy to merge iTerm2 preferences.
* Add note about setting up SSH keys before running.
* Mention installing Command-Line Tools for Xcode.
* Document upload process.
* Make a script that does some of the stuff in the `README`.

Low Priority
------------

* Update Hosted Chef URL (http://api.opscode.com/) to the new one (presumably http://api.chef.io/) one when it changes (generate a new knife config and see what's in there). Also update `cookbooks/README.md` from [chef-repo](https://github.com/chef/chef-repo) when that gets updated.
* Start using the [Chef Development Kit](https://docs.chef.io/install_dk.html), maybe. Things seem to be working OK now, but the Chef DK looks like "what everyone's using". Not sure, though.
* Automatically install default Python packages (see dotfiles as well for how this is done currently).
* Eclipse
    * PyDev and configuration
    * Emacs+ and configuration
* Things to add
    * Highlight
    * Ukelele (maybe)
    * Xerox printer drivers
    * Calibre
    * uTorrent
* We've had some permission problems with `/opt` and Homebrew Cask. When doing a clean re-install, try to resolve these if they're not resolved by the project's maintainers.

  The problem is that the default group of `/opt` (at least on Mavericks) is `wheel`, not `admin`. For example, when set what we think is correctly, both `/Applications` and `/usr/local` are set to `root:admin` with group writability. We've solved the problem currently by running:

        sudo chgrp admin /opt
        sudo chmod g+w /opt

* [fuse-zip](https://code.google.com/p/fuse-zip/) Currently weird because this would be best to install with regular Homebrew, but we are currently installing OSXFUSE (and SSHFS) through Homebrew Cask. Might want to reconsider this if installing fuse-zip. However, we are installing Macfusion through Homebrew Cask which depends on the Cask version of OSXFUSE.
* Login items are controlled by `~/Library/Preferences/com.apple.loginitems.plist`, which is can be viewed in System Preferences > Users & Group > Current User > Login Items. However, this plist appears not to be able to be edited manually. There appear to be two options: modify this plist programmatically using OS X APIs, or create launchd launch agents for each program. The first is preferrable because it allows customization through the UI, but is also more difficult. See [this StackOverflow](http://stackoverflow.com/q/12086638) question for more info.
* Add [sysdig](http://www.sysdig.org/) if and when it gets [live capture support on OS X](https://github.com/draios/sysdig/wiki/How-to-Install-Sysdig-for-Windows-and-OSX).
