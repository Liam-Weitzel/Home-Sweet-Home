gnome-terminal --working-directory=$HOME/.bash_scripts/ -- bash -c -l "tmux new -A -s services 'sudo -E bash \"startservices.sh\"'"
