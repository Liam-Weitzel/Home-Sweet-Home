#!/usr/bin/env bash

ONCLICK="$1"

VOLUME_STRING=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{printf "%.0f%%", $2 * 100; if ($3 == "[MUTED]") print " (muted)"; else print ""}')

if [ "$ONCLICK" = "true" ]; then
    echo -n "$VOLUME_STRING" | wl-copy
else
    echo "{\"text\": \"🔊 $VOLUME_STRING\"}"
fi
