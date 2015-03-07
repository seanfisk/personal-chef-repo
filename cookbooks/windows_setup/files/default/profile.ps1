# Use the Git and posh-git from GitHub for Windows.
# See <http://stackoverflow.com/a/12524788>
. (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
. $env:github_posh_git\profile.example.ps1

Import-Module PSReadLine
Set-PSReadlineOption -EditMode Emacs

# Shortcut for running chef-client. '-A' makes chef-client fail out if
# not run as administrator.
function converge {
	chef-client -A
}
