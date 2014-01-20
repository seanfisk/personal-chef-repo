* Document upload process.
* Remove redundancy in iTerm2 plist file in relation to background image.
    * Should use templates.
    * Should not use a hard-coded path (e.g., `/Users/sean`)
* Make a script that does some of the stuff in the README.
* Make tmux-MacOSX-pasteboard its own cookbook.
* zip package
    * Consider renaming it to something better. Remember the trouble with the imports though.
    * Revise the CHANGELOG and README.
    * Consider changing the `cp -R` in the installation to a ruby block.
    * Remove the temp directory when done.
* Things to add
    * texlive
    * SizeWell and SIMBL (SIMBL should be pretty simple, SizeWell more difficult)
        * But first checkout Slate.
    * Chicken, CoRD, or similar
    * Highlight
    * Flash Player standalone
    * Inkscape
    * Gimp, Seashore, or Paintbrush?
    * Network Connect (probably not easy to automate)
    * Ukelele (maybe)
    * Xerox printer drivers
    * Calibre
    * uTorrent
    * Mention installing Command-Line Tools for Xcode.
    * Add note about setting up SSH keys before running.
* Check for these applications from the App Store or otherwise
    * Caffeine
    * Skitch
    * Seagate Dashboard (for my external drive, probably not easy to automate)
* Deferred / "Not Possible"
    * Swap Caps Lock and Control
* Consider turning on `finder`, `kbaccess`, `key_repeat`, and `firewall` from `mac_os_x` cookbook.
