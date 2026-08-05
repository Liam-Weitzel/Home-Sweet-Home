#!/usr/bin/env bash
~/.config/waybar/generator.sh # initial run on startup

swaymsg -t subscribe -m '["output"]' | while read -r _; do
  ~/.config/waybar/generator.sh
done
