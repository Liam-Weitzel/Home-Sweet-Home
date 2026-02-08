#!/usr/bin/env bash

ONCLICK="$1"
LOW_BAT=30

BAT_SUM=0
BAT_COUNT=0
ON_AC=false

for PS in /sys/class/power_supply/*; do
    TYPE=$(cat "$PS/type" 2>/dev/null) || continue

    case "$TYPE" in
        Battery)
            # Ignore HID / peripheral batteries
            [[ "$(basename "$PS")" == hid-* ]] && continue

            if [ -r "$PS/capacity" ]; then
                VAL=$(cat "$PS/capacity")
                BAT_SUM=$((BAT_SUM + VAL))
                BAT_COUNT=$((BAT_COUNT + 1))
            fi
            ;;
        Mains)
            if [ -r "$PS/online" ] && [ "$(cat "$PS/online")" = "1" ]; then
                ON_AC=true
            fi
            ;;
    esac
done

if [ "$BAT_COUNT" -gt 0 ]; then
    BAT_VAL=$((BAT_SUM / BAT_COUNT))
    BAT_TEXT="${BAT_VAL}%"
else
    BAT_VAL=""
    BAT_TEXT="N/A"
fi

# Choose icon
ICON="🔋"

if [ "$ON_AC" = true ]; then
    ICON="⚡"
elif [ -n "$BAT_VAL" ] && [ "$BAT_VAL" -le "$LOW_BAT" ]; then
    ICON="🪫"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$BAT_TEXT" | wl-copy
else
    echo "{\"text\": \"$ICON $BAT_TEXT\"}"
fi
