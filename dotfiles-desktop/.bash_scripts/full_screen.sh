#!/bin/bash

MARGIN=30

window_json=$(swaymsg -t get_tree | jq '.. | select(.focused? == true)')
con_id=$(echo "$window_json" | jq '.id')
state_file="/tmp/sway_float_toggle_${con_id}.json"

output_json=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused)')
screen_width=$(echo "$output_json" | jq '.rect.width' | cut -d'.' -f1)
screen_height=$(echo "$output_json" | jq '.rect.height' | cut -d'.' -f1)

new_width=$((screen_width - 2 * MARGIN))
new_height=$((screen_height - 2 * MARGIN))
new_x=$((MARGIN))
new_y=$((MARGIN))

# Current window floating state and rect
floating=$(echo "$window_json" | jq -r '.floating')  # -r for raw string, no quotes
rect=$(echo "$window_json" | jq '.rect')
x=$(echo "$rect" | jq '.x' | cut -d'.' -f1)
y=$(echo "$rect" | jq '.y' | cut -d'.' -f1)
width=$(echo "$rect" | jq '.width' | cut -d'.' -f1)
height=$(echo "$rect" | jq '.height' | cut -d'.' -f1)

margin_tolerance=30

echo "DEBUG: floating = '$floating'"
echo "DEBUG: window x=$x, y=$y, width=$width, height=$height"
echo "DEBUG: target x=$new_x, y=$new_y, width=$new_width, height=$new_height"
echo "DEBUG: margin tolerance = $margin_tolerance"

is_fullscreen=false
if [[ "$floating" == "user_on" ]]; then
  echo "DEBUG: floating is 'user_on', checking position and size..."

  cond_x=$(( x >= new_x - margin_tolerance && x <= new_x + margin_tolerance ))
  cond_y=$(( y >= new_y - margin_tolerance && y <= new_y + margin_tolerance ))
  # Relaxed size: width and height just need to be >= target - margin_tolerance
  cond_w=$(( width >= new_width - margin_tolerance ))
  cond_h=$(( height >= new_height - margin_tolerance ))

  echo "DEBUG: condition x: $cond_x"
  echo "DEBUG: condition y: $cond_y"
  echo "DEBUG: condition width (>= target - margin): $cond_w"
  echo "DEBUG: condition height (>= target - margin): $cond_h"

  if (( cond_x && cond_y && cond_w && cond_h )); then
    is_fullscreen=true
  fi
else
  echo "DEBUG: floating is not 'user_on' (is '$floating'), skipping fullscreen check"
fi

echo "DEBUG: is_fullscreen = $is_fullscreen"

if $is_fullscreen; then
  echo "DEBUG: Window is fullscreen, restoring previous state if available"

  if [ -f "$state_file" ]; then
    prev_state=$(cat "$state_file")
    prev_floating=$(echo "$prev_state" | jq -r '.floating')
    prev_rect=$(echo "$prev_state" | jq '.rect')

    echo "DEBUG: previous floating = '$prev_floating'"
    echo "DEBUG: restoring previous size and position"

    if [[ "$prev_floating" == "user_on" ]]; then
      prev_width=$(echo "$prev_rect" | jq '.width')
      prev_height=$(echo "$prev_rect" | jq '.height')
      prev_x=$(echo "$prev_rect" | jq '.x')
      prev_y=$(echo "$prev_rect" | jq '.y')

      swaymsg -r "[con_id=$con_id] floating enable; resize set width $prev_width px height $prev_height px; move position $prev_x $prev_y"
    else
      swaymsg "[con_id=$con_id]" floating disable
    fi
    rm "$state_file"
  else
    echo "DEBUG: No saved state found, disabling floating"
    swaymsg "[con_id=$con_id]" floating disable
  fi
else
  echo "DEBUG: Window is NOT fullscreen, saving state and setting fullscreen"

  echo "{\"floating\": \"$floating\", \"rect\": $rect}" > "$state_file"

  swaymsg -r "[con_id=$con_id] floating enable; resize set $new_width $new_height; move position $new_x $new_y"
fi
