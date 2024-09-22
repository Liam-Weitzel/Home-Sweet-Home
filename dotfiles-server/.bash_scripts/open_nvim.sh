echo "nvim" > /proc/$$/comm

if ! { [ -n "${TMUX}" ]; } then 
    if [ -z $1 ]; then 
	tmux new "sudo -E -s nvim $1"
	exit 0
    else
	tmux new -A -s $1 "sudo -E -s nvim $1"
	exit 0
    fi
fi

sudo -E -s nvim $1
