#!/usr/bin/env bash

# Find our ancestor foot PID using ps
pid=$$
foot_pid=$(ps -o pid,comm -p $pid --ppid $pid | grep -w foot | awk '{print $1}' | head -n1)

# If that didn't work, walk up manually with ps
if [ -z "$foot_pid" ]; then
  while [ "$pid" != "1" ] && [ -n "$pid" ]; do
    comm=$(ps -o comm= -p "$pid" 2>/dev/null)
    if [ "$comm" = "foot" ]; then
      foot_pid=$pid
      break
    fi
    pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  done
fi

# Exit if we couldn't find foot
[ -z "$foot_pid" ] || [ "$foot_pid" = "1" ] && exit 0

# Get the entire sway tree
tree=$(swaymsg -t get_tree)

# Check if our foot window is focused
focused_pid=$(echo "$tree" | jq '.. | select(.focused? == true) | .pid')
[ -n "$focused_pid" ] && [ "$foot_pid" = "$focused_pid" ] && exit 0

# Check if our window is visible
is_visible=$(echo "$tree" | jq -r --arg pid "$foot_pid" '.. | select(.pid? == ($pid | tonumber)) | .visible?' | head -n1)

# Only notify if window is not visible
[ "$is_visible" != "true" ] && notify-send 'Claude Code' 'Waiting for input'
exit 0
