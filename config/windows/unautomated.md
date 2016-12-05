Unautomated Setup
=================

This file lists parts of Windows setup that are not automated. Typically, this is due to technical or practical reasons.

* PowerShell execution policy [We've had various problems when running this from Chef. Not worth the trouble]
* Power Plan Assistant
  Turning off the keyboard backlight initially isn't automated. Luckily, it persists between restarts when Power Plan Assistant is running.
* Trackpad++ configuration
* All Boot Camp software
* NVIDIA driver updates (Boot Camp installs old drivers)
* All VMWare virtual machine software
* Diablo 2
* Microsoft Office
* Visual Studio
* Skitch Desktop and Skitch Touch
* RCT2 GoG; UCES
* Powertab installation and config (see todos)
* LastPass (Chocolatey package seems not to work)
