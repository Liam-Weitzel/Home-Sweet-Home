#!/bin/bash

SCRIPTS_PATH="$HOME/.bash_scripts"
cd "$SCRIPTS_PATH"

if [ `find ./ -type f | wc -l` == "0" ]; then #empty scripts folder
	exit 0;
fi

script=`find ./ -type f | cut -d '/' -f 2- | grep "app" | sort | dmenu $@`

if [ "x$script" == "x" ]; then
  exit 1
fi

#sessionName="${script//.}"
#gnome-terminal --working-directory=$HOME/.bash_scripts/ -- bash -c -l "tmux new -A -s $sessionName 'sudo -E bash \"$script\"'"
bash $script
exit $?
