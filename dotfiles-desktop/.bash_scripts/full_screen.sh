#!/run/current-system/sw/bin/bash

MARGIN=0
MARGIN_TOL=30

# Get focused window
win_json=$(swaymsg -t get_tree | jq '.. | select(.focused? == true)')
con_id=$(echo "$win_json" | jq '.id')
state_file="/tmp/sway_float_toggle_${con_id}.json"

# Window geometry
win_rect=$(echo "$win_json" | jq '.rect')
win_x=$(echo "$win_rect" | jq '.x' | cut -d'.' -f1)
win_y=$(echo "$win_rect" | jq '.y' | cut -d'.' -f1)
win_w=$(echo "$win_rect" | jq '.width' | cut -d'.' -f1)
win_h=$(echo "$win_rect" | jq '.height' | cut -d'.' -f1)
floating=$(echo "$win_json" | jq -r '.floating')

# Determine which output the window is on
outputs=$(swaymsg -t get_outputs)
output=$(echo "$outputs" | jq -r --arg x "$win_x" --arg y "$win_y" \
    '.[] | select((.rect.x <= ($x|tonumber)) and (($x|tonumber) < .rect.x + .rect.width) 
                  and (.rect.y <= ($y|tonumber)) and (($y|tonumber) < .rect.y + .rect.height))')

screen_x=$(echo "$output" | jq '.rect.x' | cut -d'.' -f1)
screen_y=$(echo "$output" | jq '.rect.y' | cut -d'.' -f1)
screen_w=$(echo "$output" | jq '.rect.width' | cut -d'.' -f1)
screen_h=$(echo "$output" | jq '.rect.height' | cut -d'.' -f1)

# Fullscreen target
target_x=$((screen_x + MARGIN))
target_y=$((screen_y + MARGIN))
target_w=$((screen_w - 2 * MARGIN))
target_h=$((screen_h - 2 * MARGIN))

# Debug info
echo "DEBUG: floating=$floating, window=($win_x,$win_y,$win_w,$win_h), screen=($screen_x,$screen_y,$screen_w,$screen_h), target=($target_x,$target_y,$target_w,$target_h)"

# Check if window is already fullscreen
is_fullscreen=false
if [[ "$floating" == "user_on" ]]; then
    [[ $win_x -ge $((target_x - MARGIN_TOL)) && $win_x -le $((target_x + MARGIN_TOL)) ]] && cond_x=1 || cond_x=0
    [[ $win_y -ge $((target_y - MARGIN_TOL)) && $win_y -le $((target_y + MARGIN_TOL)) ]] && cond_y=1 || cond_y=0
    [[ $win_w -ge $((target_w - MARGIN_TOL)) ]] && cond_w=1 || cond_w=0
    [[ $win_h -ge $((target_h - MARGIN_TOL)) ]] && cond_h=1 || cond_h=0

    (( cond_x && cond_y && cond_w && cond_h )) && is_fullscreen=true
fi

echo "DEBUG: is_fullscreen=$is_fullscreen"

if $is_fullscreen && [ -f "$state_file" ]; then
    # Restore previous size/position
    prev_state=$(cat "$state_file")
    prev_floating=$(echo "$prev_state" | jq -r '.floating')
    prev_rect=$(echo "$prev_state" | jq '.rect')
    prev_x=$(echo "$prev_rect" | jq '.x')
    prev_y=$(echo "$prev_rect" | jq '.y')
    prev_w=$(echo "$prev_rect" | jq '.width')
    prev_h=$(echo "$prev_rect" | jq '.height')

    rel_x=$((prev_x - screen_x))
    rel_y=$((prev_y - screen_y))

    if [[ "$prev_floating" == "user_on" ]]; then
        swaymsg -r "[con_id=$con_id] floating enable; resize set width $prev_w px height $prev_h px; move position $rel_x $rel_y"
    else
        swaymsg "[con_id=$con_id]" floating disable
    fi

    rm "$state_file"
else
    # Save current state and make fullscreen
    echo "{\"floating\": \"$floating\", \"rect\": $win_rect}" > "$state_file"

    rel_x=$((target_x - screen_x))
    rel_y=$((target_y - screen_y))

    swaymsg -r "[con_id=$con_id] floating enable; resize set $target_w $target_h; move position $rel_x $rel_y"
fi
