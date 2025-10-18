#!/usr/bin/env bash

ONCLICK="$1"

PING_MS=$(ping -c1 -W1 google.com 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
if [ -z "$PING_MS" ]; then
    PING_TEXT="N/A"
else
    PING_TEXT="${PING_MS}ms"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PING_TEXT" | wl-copy
else
    echo "{\"text\": \"🔄 $PING_TEXT\"}"
fi
