# Use the Git and posh-git from GitHub for Windows.
# See <http://stackoverflow.com/a/12524788>
. (Resolve-Path "$env:LOCALAPPDATA\GitHub\shell.ps1")
. $env:github_posh_git\profile.example.ps1

# Make the ChefDK Ruby our primary Ruby. See here:
# - https://docs.chef.io/install_dk.html#powershell
# - https://www.chef.io/blog/2014/11/04/the-chefdk-on-windows-survival-guide/
chef shell-init powershell | Invoke-Expression

Import-Module PSReadLine
Set-PSReadlineOption -EditMode Emacs

# Shortcut for running chef-client. '-A' makes chef-client fail out if
# not run as administrator.
function converge {
	chef-client -A
}

function which ([string]$cmd) {
	# Use Definition instead of Path to work better with Cmdlets
	(Get-Command $cmd).Definition
}

# Matches aliases in dotfiles
New-Alias ccopy clip
New-Alias cpaste paste
New-Alias c Set-Location
New-Alias l Get-ChildItem
function u {
	 Set-Location ..
}
New-Alias py python
New-Alias ipy ipython
