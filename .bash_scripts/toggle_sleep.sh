#!/bin/bash

# Check if DPMS is currently enabled
DPMS_STATUS=$(xset -q | grep 'DPMS is' | awk '{ print $3 }')

if [ "$DPMS_STATUS" = "Enabled" ]; then
    # If DPMS is enabled, disable it and set screen saver to 0
    xset s 0 0 -dpms
    echo "Screen will now stay awake."
else
    # If DPMS is disabled, enable it and set screen saver to turn off screen after 1 minute
    xset s 60 60 +dpms
    echo "Screen will turn off after 1 minute of inactivity."
fi
