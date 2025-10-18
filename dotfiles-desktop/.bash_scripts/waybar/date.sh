#!/usr/bin/env bash

ONCLICK="$1"
DATE_TEXT=$(date +'%Y-%m-%d %X')

if [ "$ONCLICK" = "true" ]; then
    echo -n "$DATE_TEXT" | wl-copy
else
    echo "{\"text\": \"🕛 $DATE_TEXT\"}"
fi
