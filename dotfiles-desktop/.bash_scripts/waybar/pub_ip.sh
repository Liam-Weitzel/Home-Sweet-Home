#!/usr/bin/env bash

ONCLICK="$1"

# Always query IPv4 only
PUBLIC_IP=$(curl -4 -s --max-time 1 https://ifconfig.me || echo "")

# Validate IPv4 format (four octets 0–255)
if [[ ! "$PUBLIC_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    PUBLIC_IP="127.0.0.1"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PUBLIC_IP" | wl-copy
else
    echo "{\"text\": \"🏘️ $PUBLIC_IP\"}"
fi
