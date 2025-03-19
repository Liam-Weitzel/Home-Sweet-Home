#!/bin/bash

# Get the name of the focused output
focused_output=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name')

# Get current scale of focused output
current_scale=$(swaymsg -t get_outputs | jq -r ".[] | select(.name == \"$focused_output\") | .scale")

# Check if we got a valid number
if ! [[ $current_scale =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    current_scale=1.0
fi

# Handle increment/decrement based on parameter
case "$1" in
    "up")
        new_scale=$(awk "BEGIN {print $current_scale + 0.1}")
        ;;
    "down")
        new_scale=$(awk "BEGIN {print $current_scale - 0.1}")
        ;;
    *)
        echo "Usage: $0 [up|down]"
        exit 1
        ;;
esac

# Ensure scale stays within reasonable bounds (0.5 to 3.0)
if (( $(awk "BEGIN {print ($new_scale < 0.5)}") )); then
    new_scale=0.5
elif (( $(awk "BEGIN {print ($new_scale > 3.0)}") )); then
    new_scale=3.0
fi

# Apply new scale to focused output only
swaymsg output "$focused_output" scale "$new_scale"
