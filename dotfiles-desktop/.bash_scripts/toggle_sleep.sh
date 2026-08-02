#!/usr/bin/env bash

SWAYLOCK_CMD="swaylock -e -f -s fill -c 2C2D30 \
--indicator-idle-visible \
--line-color 2C2D30 --line-ver-color 2C2D30 --line-wrong-color 2C2D30 --line-clear-color 2C2D30 \
--inside-color 2C2D30 --inside-wrong-color 2C2D30 --inside-ver-color 2C2D30 --inside-clear-color 2C2D30 \
--ring-color 2C2D30 --ring-wrong-color E16D77 --ring-ver-color 68AEE8 --ring-clear-color FF9E64 \
--text-clear-color FF9E64 --text-wrong-color E16D77 --text-ver-color 68AEE8 \
--key-hl-color 99BC80 --bs-hl-color E16D77 --separator-color 2C2D30\
"

# Function to enable sleep (lid-close triggers suspend)
enable_sleep() {
    pkill swayidle
    pkill -f "systemd-inhibit.*handle-lid-switch"

    nohup swayidle -w \
      timeout 180 'swaymsg "output * dpms off"' \
        resume 'swaymsg "output * dpms on"' \
      timeout 360 'systemctl suspend-then-hibernate' \
      before-sleep "$SWAYLOCK_CMD" &

    notify-send "Sleep enabled" "Idle + lid actions restored"
}

# Function to disable sleep (ignore lid)
disable_sleep() {
    # Kill swayidle
    pkill swayidle

    # Prevent suspend/hibernate even on lid close
    nohup systemd-inhibit --what=handle-lid-switch sleep infinity >/dev/null 2>&1 &

    notify-send "Sleep disabled" "No idle, no lid sleep"
}

# Function to instantly lock
lock() {
    $SWAYLOCK_CMD
}

# Main logic
if [[ "$1" == "--lock" ]]; then
    lock
else
    pgrep -u "$USER" -x swayidle >/dev/null
    if [ $? -eq 0 ]; then
        disable_sleep
    else
        enable_sleep
    fi
fi
