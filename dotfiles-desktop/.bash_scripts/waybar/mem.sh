#!/usr/bin/env bash

ONCLICK="$1"

MEM_USED=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%.1f/%.1fG", (t-a)/1024/1024, t/1024/1024}' /proc/meminfo)

if [ "$ONCLICK" = "true" ]; then
    echo -n "$MEM_USED" | wl-copy
else
    echo "{\"text\": \"MEM: $MEM_USED\"}"
fi
