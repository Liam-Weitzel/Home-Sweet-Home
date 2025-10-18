#!/usr/bin/env bash

ONCLICK="$1"

IFACE=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev"){print $(i+1);exit}}}')
[ -z "$IFACE" ] && IFACE="N/A"

NET_FILE="/tmp/waybar_net_prev"
if [ -f "$NET_FILE" ]; then
    read PREV_RX PREV_TX < "$NET_FILE"
else
    PREV_RX=0
    PREV_TX=0
fi

if [ "$IFACE" != "N/A" ]; then
    RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
    TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
    DOWN=$(( (RX - PREV_RX)/1024 ))
    UP=$(( (TX - PREV_TX)/1024 ))
    echo "$RX $TX" > "$NET_FILE"
else
    DOWN=0
    UP=0
fi

NET_TEXT="↓ ${DOWN} KB/s ↑ ${UP} KB/s"

if [ "$ONCLICK" = "true" ]; then
    echo -n "$NET_TEXT" | wl-copy
else
    echo "{\"text\": \"NET: $NET_TEXT\"}"
fi
