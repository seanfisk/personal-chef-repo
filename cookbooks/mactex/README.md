MacTeX Cookbook
===============

Installs [MacTeX][mactex] on macOS.

This was made into a cookbook separate from `macos_setup` because MacTeX is a large install and not necessary for bootstrapping a system for development.

**Note:** MacTeX is a huge download. If you already have it downloaded, but still want to use it as part of this setup, move the file into Chef's cache path.

For example, you could use `aria2` to download MacTeX through the torrent network:
```bash
cd ~/Downloads
aria2c http://www.tug.org/mactex/mactex-20170524.pkg.torrent
```

Then move it into Chef's cache:
```bash
mv ~/Downloads/mactex-20170524.pkg ~/.chef/cache/MacTeX.pkg
```

[mactex]: http://tug.org/mactex/downloading.html

Requirements
------------

Only works on macOS. Tested on OS X 10.11 El Capitan.

Usage
-----

Just include `mactex` in your node's `run_list` to install.
