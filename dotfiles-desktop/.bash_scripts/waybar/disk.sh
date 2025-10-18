#!/usr/bin/env bash

ONCLICK="$1"
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2}')

if [ "$ONCLICK" = "true" ]; then
    echo -n "$DISK" | wl-copy
else
    echo "{\"text\": \"DISK: $DISK\"}"
fi
