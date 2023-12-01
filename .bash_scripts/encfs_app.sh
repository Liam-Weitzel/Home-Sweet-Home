gnome-terminal --working-directory=$HOME/.bash_scripts/ -- bash -c -l "tmux new -A -s decryptencfs 'sudo -E bash \"decrypt_encfs.sh\"'; 
tmux new -A -s openencfs 'sudo -E bash \"open_encfs.sh\"';
tmux new -A -s umountencfs 'sudo -E bash \"umount_encfs.sh\"'"
