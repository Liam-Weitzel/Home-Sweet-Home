#!/usr/bin/env bash

ONCLICK="$1"

IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1);exit}}}')
[ -z "$IFACE" ] && IFACE="N/A"

if [[ $IFACE == wlan* ]]; then
    SSID=$(iwgetid -r 2>/dev/null || echo "Wi-Fi")
else
    SSID="ETH"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$SSID" | wl-copy
else
    echo "{\"text\": \"🛜 $SSID\"}"
fi
