panda3d Cookbook
================

Installs the [Panda3D][panda3d] game engine SDK on Mac OS X.

[panda3d]: http://www.panda3d.org/

Requirements
------------

Only works on Mac OS X. Tested on Mac OS 10.9 Mavericks.

Usage
-----

Just include `panda3d` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[panda3d]"
  ]
}
```
