* Start using the [Chef Development Kit](https://docs.chef.io/install_dk.html), maybe. Things seem to be working OK now, but the Chef DK looks like "what everyone's using". Not sure, though.
* Login items, controlled by `~/Library/Preferences/com.apple.loginitems.plist`.
* Update URLs and mentions for name change to chef.io (as of time of writing, Hosted Chef is still api.opscode.com; wait until this changes to make the update)
* Use PlistBuddy to merge iTerm2 preferences.
* Accessibility
    * Zoom
    * Picture-in-picture
* Automatically install devpi and/or system Python packages (see dotfiles as well).
* [MacFusion](http://macfusionapp.org/)
* Add guards to stop resources from updating if they don't need to.
* Add checksums to fonts, or use `:create_if_missing`.
* Document upload process.
* Make a script that does some of the stuff in the README.
* Eclipse
    * PyDev and configuration
    * Emacs+ and configuration
* Things to add
    * Highlight
    * Ukelele (maybe)
    * Xerox printer drivers
    * Calibre
    * uTorrent
    * Mention installing Command-Line Tools for Xcode.
    * Add note about setting up SSH keys before running.
maintain.
* Consider turning on `kbaccess` from `mac_os_x` cookbook.
* [fuse-zip](https://code.google.com/p/fuse-zip/) Currently weird because this would be best to install with Homebrew, but we are currently installing OSXFUSE (and SSHFS) through their pkg installers. Might want to reconsider this when installing fuse-zip.
* We've had some permission problems with `/opt` and Homebrew Cask. When doing a clean re-install, try to resolve these if they're not resolved by the project's maintainers.

  The problem is that the default group of `/opt` (at least on Mavericks) is `wheel`, not `admin`. For example, when set what we think is correctly, both `/Applications` and `/usr/local` are set to `root:admin` with group writability. We've solved the problem currently by running:

        sudo chgrp admin /opt
        sudo chmod g+w /opt
