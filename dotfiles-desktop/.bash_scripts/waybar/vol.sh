#!/usr/bin/env bash

ONCLICK="$1"

VOLUME_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)

VOLUME_PERCENT=$(echo "$VOLUME_INFO" | awk '{printf "%.0f%%", $2 * 100}')
IS_MUTED=$(echo "$VOLUME_INFO" | grep -q "\[MUTED\]" && echo "true" || echo "false")

if [ "$IS_MUTED" = "true" ]; then
    ICON="🔇"
    VOLUME_STRING="$VOLUME_PERCENT"
else
    ICON="🔊"
    VOLUME_STRING="$VOLUME_PERCENT"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$VOLUME_STRING" | wl-copy
else
    echo "{\"text\": \"$ICON $VOLUME_STRING\"}"
fi
