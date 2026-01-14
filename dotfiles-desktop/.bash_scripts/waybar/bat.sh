#!/usr/bin/env bash

ONCLICK="$1"

BAT_VAL=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo "N/A")
BAT_TEXT=$( [ "$BAT_VAL" != "N/A" ] && printf "%s%%" "$BAT_VAL" || echo "N/A" )

if [ "$ONCLICK" = "true" ]; then
    echo -n $BAT_TEXT | wl-copy
else
    echo "{\"text\": \"🔋 $BAT_TEXT\"}"
fi
