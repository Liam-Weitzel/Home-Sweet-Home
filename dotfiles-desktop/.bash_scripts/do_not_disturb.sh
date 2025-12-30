#!/run/current-system/sw/bin/bash

# Usage info
usage() {
    echo "Usage: $0 [--enable | --disable]"
    exit 1
}

# Handle flags
if [[ "$1" == "--enable" ]]; then
    makoctl mode -r hide
    notify-send "Notifications are now visible."
    exit 0
elif [[ "$1" == "--disable" ]]; then
    makoctl mode -s hide
    echo "Notifications are now hidden."
    exit 0
elif [[ -n "$1" ]]; then
    usage
fi

# Default toggle behavior
if makoctl mode | grep -q "hide"; then
    makoctl mode -r hide
    notify-send "Notifications are now visible."
else
    makoctl mode -s hide
    echo "Notifications are now hidden."
fi
