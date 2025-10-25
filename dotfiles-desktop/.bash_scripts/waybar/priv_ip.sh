#!/usr/bin/env bash

ONCLICK="$1"

# Get active IPv4 interface
IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1);exit}}}')
[ -z "$IFACE" ] && IFACE=""

# Extract IPv4 private address
PRIVATE_IP=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/inet/ {print $2}' | cut -d/ -f1 | \
             grep -E '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.' | head -n1)

# Validate IPv4 format
if [[ ! "$PRIVATE_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    PRIVATE_IP="127.0.0.1"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PRIVATE_IP" | wl-copy
else
    echo "{\"text\": \"🏠 $PRIVATE_IP\"}"
fi
