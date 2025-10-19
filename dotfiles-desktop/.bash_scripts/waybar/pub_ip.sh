#!/usr/bin/env bash

ONCLICK="$1"

# Try IPv4 first, fall back to IPv6 if needed
PUBLIC_IP=$(curl -4 -s --max-time 1 https://ifconfig.me || \
            curl -6 -s --max-time 1 https://ifconfig.me || \
            echo "N/A")

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PUBLIC_IP" | wl-copy
else
    echo "{\"text\": \"🏘️ $PUBLIC_IP\"}"
fi
