* Fix SSL warning that gets dumped every run of `chef-client`.
* Die with a warning if running without admin privileges. Document what needs it.
* Fix Powertab installation with Chocolatey. It only seems to work with Windows Powershell (x86) [from Administrative Tools] run as Administrator. And even that only works in the x86 console itself. Argh.
* Decide on an SSH and VNC client and uninstall all others.
* ConEmu, Git, and Posh configs. Get .gitconfig from dotfiles, make Windows compatible. Not sure exactly how we'll do that yet.
* Steam
* Consider adding Chocolatey packages:
    * Posh-VsVars
    * sysinterals
    * PowerGUI
    * PsGet
* Pester (PowerShell testing framework) looks neat.