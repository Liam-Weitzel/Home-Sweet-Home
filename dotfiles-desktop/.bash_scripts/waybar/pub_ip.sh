#!/usr/bin/env bash

ONCLICK="$1"

PUBLIC_IP=$(curl -s --max-time 1 https://ifconfig.me || echo "N/A")

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PUBLIC_IP" | wl-copy
else
    echo "{\"text\": \"🏘️ $PUBLIC_IP\"}"
fi
