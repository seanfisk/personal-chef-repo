Unautomated Setup
=================

This file lists parts of Mac OS X setup that are not automated. Typically, this is due to technical or practical reasons.

* Mac App Store downloads

    * Caffeine (free)
    * Skitch (free)
    * aText (paid)

* Seagate Dashboard

  Installed with my Seagate external hard drive. Hard to automate, since the software is on the drive itself. May not want to automate, since this seems very specific to the device itself.

* Swap Caps Lock and Control

  Apparently, not really too easy to automate. I haven't looked into it too much, since it's pretty easy to do manually.

* Desktop backgrounds

  This is a little overkill. It's nice to automate, but I change these from time to time manually, and that would be just one more thing to change every time.

* [Deeper](http://www.titanium.free.fr/downloaddeeper.php)

  We're currently using this to change the login screen background. It's specific to the version of OS X. Not impossible to automate, but we haven't chosen to yet.

* GVSU's VPN (Network Connect)

  This comes from GVSU, and the versions need to remain consistent.

* Xcode

  Installs using the Mac App Store. With Homebrew and normal C++ compiles, we can get along with just the Command-Line Tools. However, to compile Mac applications using Qt, we need the full Xcode installation.

* Qt 5

  This is installed using an application installer (an app bundle in the DMG which installs Qt), and is therefore hard to automate.

* Adobe Flash Player and Adobe Reader

  They have an app bundle inside the DMG, making it hard to automate installation.

* Microsoft DreamSpark's Secure Download Manager

  This is just installed because it was needed. Should probably uninstall when not needed anymore.

* LastPass

  The universal installer has installer and uninstaller app bundles. Pretty annoying and difficult to automate. Alternatively, we could install just for Firefox and let Firefox sync the add-on (maybe?).

* Firefox

  Disable the auto-redirection of domains. Specifically this is annoying for `localhost`. Hopefully this will be synced. See http://cdivilly.wordpress.com/2013/08/15/disable-firefox-redirecting-to-localhost-com/.

* Xerox WorkCenter 5755 Printer Drivers

  For advanced use of GVSU's printers.
