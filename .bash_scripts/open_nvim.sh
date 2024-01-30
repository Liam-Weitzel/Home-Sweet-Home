if ! { [ -n "${TMUX}" ]; } then 
    tmux new -A -s nvim "sudo -E -s ~/nvim $1"
    exit 0
fi

sudo -E -s ~/nvim $1
