Unautomated Setup
=================

This file lists parts of macOS setup that are not automated. Typically, this is due to technical or practical reasons.

* SSH key generation

  Run `ssh-keygen`, upload to GitHub, and copy the public key to necessary servers.

* Dotfiles installation

  This used to be automated, but since moving to Waf, it is probably a good idea to set up pyenv with a virtualenv to do it correctly. While this could be automated, there isn't a large benefit in doing it right now since I only have one machine.

* aText

  This is licensed software that is installed using Homebrew Cask. I purchased it from the Mac App Store (MAS). However, as stated in [aText Support](http://www.trankynam.com/atext/support.html), the non-MAS version generally works better. You'll have to follow the process to migrate your MAS license to get the non-MAS version working.

  When using the launch agent approach to start up aText, it does not validate the license. So we're just going for the regular startup process.

* Jettison

  This is licensed software that is installed using the dmg cookbook. I purchased a license that has to be manually entered/activated. Don't get confused: I initially purchased Jettison from the Mac App Store, but bought a separate license when I found that the Mac App Store version isn't up-to-date.

* Cathode

  This is licensed software that is installed using Homebrew Cask. I purchased a license that has to be manually activated.

* Quicksilver hotkey

  Most of the other preferences are automated, but this one proved difficult. For now, it needs to be set manually. See the recipe for the gritty details and rationale for the decision not to automate.

* Desktop backgrounds

  This is a little overkill. It's nice to automate, but I change these from time to time manually, and that would be just one more thing to change every time.

* Xcode

  Installs using the Mac App Store. With Homebrew and normal C++ compiles, we can get along with just the Command-Line Tools. However, to compile Mac applications using Qt, we need the full Xcode installation.

* LastPass

  - The universal installer has installer and uninstaller app bundles that need to be run manually. Using the universal installer is preferable to individual browser add-ons due to the inclusion of all browser add-ons and the binary component, which allows sharing state between browsers. The universal installer is not present in Homebrew, Homebrew Cask, or the Mac App Store and must be downloaded manually from here: https://lastpass.com/misc_download2.php

* Firefox

  - Disable the auto-redirection of domains. Specifically this is annoying for `localhost`. Hopefully this will be synced. See http://cdivilly.wordpress.com/2013/08/15/disable-firefox-redirecting-to-localhost-com/.
  - Google Talk plugin needs to be blocked, as it forces a transition to the discrete GPU even when the plugin really isn't being used [i.e., not in hangouts]).

* Karabiner

  This does not start up properly when using the launch agent approach, so we just use native startup support through the app itself.
