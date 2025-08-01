alias nixsw='sudo nixos-rebuild switch --flake ~/Home-Sweet-Home/flake.nix#liam-w'
alias nixswv='sudo nixos-rebuild switch --flake ~/Home-Sweet-Home/flake.nix#liam-w -vvvv'
alias lg='lazygit'
alias lq='lazysql'
alias bt='bluetuith'
alias nm='nmtui'
alias mail='neomutt'
alias dk='tui-deck'

vi() {
    nvim "$@"
}

# enable color support for commands
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
