MacTeX Cookbook
===============

Installs [MacTeX][mactex] on Mac OS X.

This was made into a cookbook separate from `osx_setup` because MacTeX is a large install and not necessary for bootstrapping a system for development.

**Note:** MacTeX is a huge download. If you already have it downloaded, but still want to use it as part of this setup, move the file into Chef's cache path.

For example, you could use `aria2` to download MacTeX through the torrent network:
```bash
cd ~/Downloads
aria2c http://www.tug.org/mactex/mactex2013.pkg.torrent
```

Then move it into Chef's cache:
```bash
mv ~/Downloads/mactex20130618.pkg ~/.chef/cache/MacTeX.pkg
```

[mactex]: http://tug.org/mactex/downloading.html

Requirements
------------

Only works on Mac OS X. Tested on Mac OS 10.9 Mavericks.

Usage
-----
#### mactex::default

Just include `mactex` in your node's `run_list` to install:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[mactex]"
  ]
}
```
