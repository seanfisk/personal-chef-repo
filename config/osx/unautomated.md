Unautomated Setup
=================

This file lists parts of Mac OS X setup that are not automated. Typically, this is due to technical or practical reasons.

* Dotfiles installation

  This used to be automated, but since moving to Waf, it is probably a good idea to set up pyenv with a virtualenv to do it correctly. While this could be automated, there isn't a large benefit in doing it right now since I only have one machine.

* aText

  This is licensed software that is installed using Homebrew Cask. I purchased it from the Mac App Store (MAS). However, as stated in [aText Support](http://www.trankynam.com/atext/support.html), the non-MAS version generally works better. You'll have to follow the process to migrate your MAS license to get the non-MAS version working.

* Jettison

  This is licensed software that is installed using Homebrew Cask. I purchased a license that has to be manually entered/activated. Don't get confused: I initially purchased Jettison from the Mac App Store, but bought a separate license when I found that the Mac App Store version isn't up-to-date.

* Cathode

  This is licensed software that is installed using Homebrew Cask. I purchased a license that has to be manually activated.

* Memory Clean

  Installed from the Mac App Store.

* Quicksilver hotkey

  Most of the other preferences are automated, but this one proved difficult. For now, it needs to be set manually. See the recipe for the gritty details and rationale for the decision not to automate.

* Seagate Dashboard

  Installed with my Seagate external hard drive. Hard to automate, since the software is on the drive itself. May not want to automate, since this seems very specific to the device itself.

* Swap Caps Lock and Control

  Apparently, not really too easy to automate. I haven't looked into it too much, since it's pretty easy to do manually.

* Desktop backgrounds

  This is a little overkill. It's nice to automate, but I change these from time to time manually, and that would be just one more thing to change every time.

* GVSU's VPN (Network Connect)

  This comes from GVSU, and the versions need to remain consistent.

* Xcode

  Installs using the Mac App Store. With Homebrew and normal C++ compiles, we can get along with just the Command-Line Tools. However, to compile Mac applications using Qt, we need the full Xcode installation.

* Qt 5

  This is installed using an application installer (an app bundle in the DMG which installs Qt), and is therefore hard to automate.

* Microsoft DreamSpark's Secure Download Manager

  This is just installed because it was needed. Should probably uninstall when not needed anymore.

* LastPass

  - The universal installer has installer and uninstaller app bundles which are downloaded by Homebrew Cask but need to be run manually. Using the universal installer is preferable to individual browser add-ons due to the inclusion of all browser add-ons and the binary component, which allows sharing state between browsers.
  - [LastPass app for OS X](https://itunes.apple.com/us/app/lastpass/id926036361?ls=1&mt=12), which is installed using the Mac App Store.

* Firefox

  - Disable the auto-redirection of domains. Specifically this is annoying for `localhost`. Hopefully this will be synced. See http://cdivilly.wordpress.com/2013/08/15/disable-firefox-redirecting-to-localhost-com/.
  - Google Talk plugin needs to be blocked, as it forces a transition to the discrete GPU even when the plugin really isn't being used [i.e., not in hangouts]).

* Login items

  The list of applications which should run at startup are currently not automated. They are:

  * gfxCardStatus
  * Quicksilver
  * Flux
  * Jettison
  * Slate
  * Monotype SkyFonts
  * aText
  * Karabiner
  * iTerm (optional, this is just for convenience)

* Xerox WorkCenter 5755 Printer Drivers

  For advanced use of GVSU's printers.
