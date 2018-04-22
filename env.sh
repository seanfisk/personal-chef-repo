if [[ $ZSH_VERSION ]]; then
	CHEFDK_SHELL=zsh
elif [[ $BASH_VERSION ]]; then
	CHEFDK_SHELL=bash
else
	echo 'Shell not supported' >&2
fi

echo -n "Loading ChefDK environment for $CHEFDK_SHELL…"
eval "$(chef shell-init "$CHEFDK_SHELL")"
echo ' Done.'
unset CHEFDK_SHELL
