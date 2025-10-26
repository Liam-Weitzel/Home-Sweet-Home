#!/usr/bin/env bash

ONCLICK="$1"

STATUS=$(curl -s https://am.i.mullvad.net/json | jq -r '.mullvad_exit_ip')
ICON="⚗️"

if [ "$STATUS" = "true" ]; then
    STATUS_STRING="On"
else
    STATUS_STRING="Off"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$STATUS_STRING" | wl-copy
else
    echo "{\"text\": \"$ICON $STATUS_STRING\"}"
fi
