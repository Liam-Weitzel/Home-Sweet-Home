#!/usr/bin/env bash

ONCLICK="$1"

UPTIME_SEC=$(cut -d. -f1 /proc/uptime)
UP_H=$((UPTIME_SEC/3600))
UP_M=$(((UPTIME_SEC%3600)/60))
UP_TEXT=$(printf "%02dh%02dm" $UP_H $UP_M)

if [ "$ONCLICK" = "true" ]; then
    echo -n "$UP_TEXT" | wl-copy
else
    echo "{\"text\": \"⬆️ $UP_TEXT\"}"
fi
