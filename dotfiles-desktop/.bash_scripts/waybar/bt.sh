#!/usr/bin/env bash

ONCLICK="$1"

# Check if Bluetooth adapter is powered
BT_STATUS=$(bluetoothctl show | awk '/Powered:/ {print $2}')

# Count connected devices
CONNECTED_COUNT=$(bluetoothctl info | grep -c "Connected: yes")

if [ "$BT_STATUS" = "yes" ]; then
    ICON="🟦"
    if [ "$CONNECTED_COUNT" -gt 0 ]; then
        TEXT="On ($CONNECTED_COUNT)"
    else
        TEXT="On"
    fi
else
    ICON="🔷"
    TEXT="Off"
fi

if [ "$ONCLICK" = "true" ]; then
    echo -n "$TEXT" | wl-copy
else
    echo "{\"text\": \"${ICON} ${TEXT}\"}"
fi
