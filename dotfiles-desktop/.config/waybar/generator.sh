#!/usr/bin/env bash
set -euo pipefail

exec 9>/tmp/waybar-generate.lock
flock -n 9 || exit 0   # if another run is in progress, just skip — a later event will trigger a fresh regen anyway

CONFIG_DIR="$HOME/.config/waybar"
OUT_FILE="$CONFIG_DIR/config.generated.json"

# Sway reports current_mode width/height already adjusted for transform,
# so a rotated (portrait) panel correctly shows height > width here.
mapfile -t VERTICAL < <(swaymsg -t get_outputs | jq -r '
  .[] | select(.active) | select(.rect.height > .rect.width) | .name')

mapfile -t HORIZONTAL < <(swaymsg -t get_outputs | jq -r '
  .[] | select(.active) | select(.rect.width >= .rect.height) | .name')

jq -n \
  --argjson vert "$(printf '%s\n' "${VERTICAL[@]:-}" | jq -R . | jq -s .)" \
  --argjson horiz "$(printf '%s\n' "${HORIZONTAL[@]:-}" | jq -R . | jq -s .)" \
  --slurpfile vcfg "$CONFIG_DIR/vertical.json" \
  --slurpfile hcfg "$CONFIG_DIR/horizontal.json" \
  '[
    ($hcfg[0] + {output: $horiz, name: "bar-horizontal"}),
    ($vcfg[0] + {output: $vert, name: "bar-vertical"})
  ] | map(select(.output | length > 0))' \
  > "$OUT_FILE"

# Match on the launched command line, not the process name: Nix wraps waybar
# so its real comm is ".waybar-wrapped", not "waybar" — `pkill -x waybar`
# never matched anything, so every regen left the old instance running and
# just kept adding new ones.
MATCH="waybar -c $OUT_FILE"

# Wait for waybar to actually exit before relaunching — a fixed sleep after
# pkill races the old process's (and Sway's) teardown of layer-shell surfaces,
# which can leave a stale instance fighting the new one over an output.
if pgrep -f "$MATCH" >/dev/null; then
  pkill -f "$MATCH" || true
  for _ in $(seq 1 50); do          # SIGTERM: up to 2.5s for a clean exit
    pgrep -f "$MATCH" >/dev/null || break
    sleep 0.05
  done
  pkill -9 -f "$MATCH" 2>/dev/null || true
  for _ in $(seq 1 20); do          # SIGKILL: up to 1s for the kernel to reap it
    pgrep -f "$MATCH" >/dev/null || break
    sleep 0.05
  done
fi

# 9>&- so waybar does not inherit the lock fd — otherwise it holds the flock
# for its entire lifetime and every later run silently skips.
waybar -c "$OUT_FILE" -s "$CONFIG_DIR/style.css" 9>&- &
disown
