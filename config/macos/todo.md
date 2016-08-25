High Priority
-------------

* `chsh` prompts for the user's password. We should switch to Directory Services (`dscl`). Although this needs root to run, this is easier because we can just use `sudo` in the recipe. See [here](http://superuser.com/questions/379725/how-do-i-change-a-users-default-shell-in-osx/379726).
* Use [tccutil](https://github.com/jacobsalmela/tccutil) to modify the accessibility database.
* [bcat](http://rtomayko.github.io/bcat/) gem (in either system Ruby or local Ruby)
* Local Python installation
* `sudo` prompts in various resources are not showing, and script is hanging waiting for them.
* Add note about setting up SSH keys before running.
* Mention installing Command-Line Tools for Xcode.
* Document upload process.
* Make a script that does some of the stuff in the `README`.
* VMWare Fusion preferences (general and BootCamp)
    * Key mappings, including mapping Control to Caps Lock now that we're using the registry hack in Windows

Low Priority
------------

* Automate [NTFS-3g installation](https://github.com/osxfuse/osxfuse/wiki/NTFS-3G#installation):
    * Install FUSE for OS X with the MacFUSE compatibility layer. This is not in the default install, so we'll probably have to mess around with options to the pkg installer using the `installer` command-line tool. Also, we'll have to remove `osxfuse` installed via Homebrew Cask.
    * Tap `homebrew/fuse`.
    * Install `ntfs-3g` formula.
    * Link NTFS-3G to the system location as shown in the steps.
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
* [fuse-zip](https://code.google.com/p/fuse-zip/) Currently weird because this would be best to install with regular Homebrew, but we are currently installing OSXFUSE (and SSHFS) through Homebrew Cask. Might want to reconsider this if installing fuse-zip. However, we are installing Macfusion through Homebrew Cask which depends on the Cask version of OSXFUSE.
* Login items are controlled by `~/Library/Preferences/com.apple.loginitems.plist`, which is can be viewed in System Preferences > Users & Group > Current User > Login Items. However, this plist appears not to be able to be edited manually. There appear to be two options: modify this plist programmatically using macOS APIs, or create launchd launch agents for each program. The first is preferrable because it allows customization through the UI, but is also more difficult. See [this StackOverflow](http://stackoverflow.com/q/12086638) question for more info.
* Add [sysdig](http://www.sysdig.org/) if and when it gets [live capture support on macOS](https://github.com/draios/sysdig/wiki/How-to-Install-Sysdig-for-Windows-and-OSX).
