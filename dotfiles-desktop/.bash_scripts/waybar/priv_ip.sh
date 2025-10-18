#!/usr/bin/env bash

ONCLICK="$1"

IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1);exit}}}')
[ -z "$IFACE" ] && IFACE="N/A"

PRIVATE_IP=$(ip -4 addr show dev "$IFACE" | grep inet | awk '{print $2}' | cut -d/ -f1 | grep -E '^10\.|^192\.168\.|^172\.(1[6-9]|2[0-9]|3[0-1])\.' | paste -sd "," -)
[ -z "$PRIVATE_IP" ] && PRIVATE_IP="N/A"

if [ "$ONCLICK" = "true" ]; then
    echo -n "$PRIVATE_IP" | wl-copy
else
    echo "{\"text\": \"🏠 $PRIVATE_IP\"}"
fi
