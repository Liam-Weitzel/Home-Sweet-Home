#!/usr/bin/env bash

# Start listening before doing anything else. If we ran generator.sh's
# (comparatively slow) first pass before subscribing, kanshi's initial
# `output ... enable` for the not-yet-negotiated monitor on a cold boot
# can fire and complete before we're subscribed, and that event is lost
# for good — leaving that output out of config.generated.json until
# something else changes. The synthetic newline below drives the first
# generator.sh run through this same loop, so subscribe is already live
# by the time it starts.
{ printf '\n'; swaymsg -t subscribe -m '["output"]'; } | while read -r _; do
  ~/.config/waybar/generator.sh
done
