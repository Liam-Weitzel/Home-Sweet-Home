#!/bin/sh
progname="$(expr "${0}" : '.*/\([^/]*\)')"

DMENU() { dmenu -p 'Grab' -l 20 -i -fn Bahamas-10 \
                -nb \#000000 -nf \#ffffff -sb \#c0c0c0 -sf \#000000; }
_usage() {
    printf "%s\\n" "Usage: ${progname} [app|title]"
    printf "%s\\n" "Dmenu window selector for i3-wm."
    printf "%s\\n"
    printf "%s\\n" "  -h, --help      show this message and exit"
}

_die() {
    [ -n "${1}" ] && _die_msg="${1}" || exit 1
    printf "%b%b\\n" "${_die_msg}" ", press <Enter> to exit" | DMENU
    exit 1
}

_i3_get_app_tree() {
    i3-msg -t get_tree | \
        egrep -o "(class\":\".[^\"]+\"|title\":\"[^\"]+)" | \
        sed 's/"//g;s/class://g;s/title://g' | \
        while read -r line; read -r line2; do  \
            printf "%s\\n" "═ ${line} :: ${line2}"; \
        done | sed '/i3bar for/d'
}

if [ ! -t 0 ]; then
    set -- "${@}" $(cat)
fi

for arg in "${@}"; do #parse options
    case "${arg}" in
        -h|--help) _usage && exit ;;
    esac
done

if [ -z "${1}" ]; then
    if ! command -v "dmenu" >/dev/null 2>&1; then
        printf "%s\\n" "${progname}: install 'dmenu' to run this program" >&2
        exit 1
    fi
    selected_entry="$(_i3_get_app_tree | DMENU)"
else
    selected_entry="$(_i3_get_app_tree | grep -i "${@}" 2>/dev/null | head -1 )"
fi

if [ -z "${selected_entry}" ]; then
    _die
else
    title="$(printf "%s\\n" "${selected_entry}" | \
        egrep -o "::.*" | sed 's/:: //g;s/\([()]\)/\\\1/g')"

    focused=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name')

    #focus window
    output_msg="$(i3-msg "[title=\"${title}\"] focus" 2>&1; i3-msg move container to workspace $focused; i3-msg "[title=\"${title}\"] focus" 2>&1)"

    if printf "%s\\n" "${output_msg}" | tail -1 | \
       grep "success" | grep "false" >/dev/null 2>&1; then
        app="${title}"; i3-msg "[class=\"${app}\"]" focus 
    fi
fi
