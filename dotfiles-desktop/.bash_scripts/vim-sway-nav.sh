#!/bin/sh
#
# vim-sway-nav - Use the same bindings to move focus between sway windows and
# vim splits. Requires the accompanying vim plugin, unless running nvim with a
# remote UI.

dir="$1"
VIM_SWAY_NAV_TIMEOUT="${VIM_SWAY_NAV_TIMEOUT:-0.1s}"
VIM_SWAY_NAV_REMOTE_TIMEOUT="${VIM_SWAY_NAV_REMOTE_TIMEOUT:-0.2s}"

case "$dir" in
    up) dir_flag=k ;;
    right) dir_flag=l ;;
    down) dir_flag=j ;;
    left) dir_flag=h ;;
    *)
        echo "USAGE: $0 up|right|down|left"
        exit 1
esac

fallback_to_sway_nav() {
    swaymsg focus "$dir"
    exit
}

focused_pid="$(swaymsg -t get_tree | jq -e '.. | select(.focused? == true).pid')" || fallback_to_sway_nav
terms="$(find /dev/pts -type c -not -name ptmx | sed s#^/dev/## | tr '\n' ,)"

get_descendant_vim_pid() {
    pid="$1"

    if grep -iqE '^g?(view|n?vim?x?)(diff)?$' "/proc/$pid/comm"; then
        if embed_pid="$(pgrep --parent "$pid" --full 'nvim --embed')"; then
            echo "$embed_pid"
        else
            echo "$pid"
        fi

        return 0
    fi

    for child in $(pgrep --runstates D,I,R,S --terminal "$terms" --parent "$pid"); do
        if get_descendant_vim_pid "$child"; then
            # already echo'd PID in recursive call
            return 0
        fi
    done

    return 1
}

vim_pid="$(get_descendant_vim_pid "$focused_pid")" || fallback_to_sway_nav
servername_file="${XDG_RUNTIME_DIR:-/tmp}/vim-sway-nav.$vim_pid.servername"
if [ -f "$servername_file" ]; then
    read -r program servername <"$servername_file"
    timeout="$VIM_SWAY_NAV_TIMEOUT"
else
    # check if it's nvim with a remote UI
    version="$("/proc/$vim_pid/exe" --version)"
    if [ "${version#NVIM}" != "$version" ]; then
        program=nvim
    else
        fallback_to_sway_nav
    fi
    sep="<SeparatorThatHopefullyNeverAppearsInAProcCmdline>"
    cmdline="$(sed "s/\x0/$sep/g" <"/proc/$vim_pid/cmdline")"
    echo "$cmdline" | grep -Eq -- "($sep|^)--remote-ui($sep|$)" || fallback_to_sway_nav
    server_and_later_args="${cmdline##*"$sep"--server"$sep"}"
    servername="${server_and_later_args%%"$sep"*}"
    timeout="$VIM_SWAY_NAV_REMOTE_TIMEOUT"
fi

[ -n "$servername" ] || fallback_to_sway_nav

with_timeout() {
    if [ -n "$timeout" ] && [ "$timeout" != 0 ] && command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" "$@"
    else
        "$@"
    fi
}

vim_remote_expr() {
    if [ "$program" = vim ]; then
        with_timeout vim --servername "$servername" --remote-expr "$@"
    elif [ "$program" = nvim ]; then
        with_timeout nvim --headless --server "$servername" --remote-expr "$@"
    fi
}

did_nav_in_vim=$(vim_remote_expr "winnr('$dir_flag') == winnr() ? 'did not nav in vim' : trim(execute(['wincmd $dir_flag', 'echo ''did nav in vim''']))")
[ "$did_nav_in_vim" = "did nav in vim" ] || fallback_to_sway_nav
