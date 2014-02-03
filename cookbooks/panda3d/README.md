panda3d Cookbook
================

Installs the [Panda3D][panda3d] game engine SDK on Mac OS X.

[panda3d]: http://www.panda3d.org/

Requirements
------------

Only works on Mac OS X. Tested on Mac OS 10.9 Mavericks.

Panda3D may additionally require the [NVIDIA Cg Toolkit][cg-toolkit]
in order to run. Since the install is annoying and it might not be
needed for every machine, this cookbook does not install it. Please
see the default recipe for more nitty-gritty details.

[cg-toolit]: https://developer.nvidia.com/cg-toolkit

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
