#!/usr/bin/env bash

# Get current workspace
current_ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .name')

# Get list of windows
window=$(swaymsg -t get_tree | jq -r '
  def flatten:
    . as $in
    | [$in]
    + ([$in.nodes[]?, $in.floating_nodes[]?] | map(flatten) | add);
  flatten[]
  | select((.type == "con" or .type == "floating_con") and .name != null)
  | "\(.id) \(.app_id // "no-app-id"): \(.name)"
' | rofi -dmenu -p "Move window here" -lines 10 -no-custom -i)

echo "Selected: '$window'" >&2

# Extract window ID (first field)
win_id=$(echo "$window" | awk '{print $1}')
echo "Parsed win_id: '$win_id'" >&2

# Move the window to the current workspace
if [[ "$win_id" =~ ^[0-9]+$ ]]; then
  swaymsg "[con_id=$win_id]" move to workspace "$current_ws"
else
  echo "❌ Invalid or missing window ID: '$win_id'" >&2
  exit 1
fi
