#!/usr/bin/env bash

ONCLICK="$1"
CPU_FILE="/tmp/waybar_cpu_prev"

CPU_CUR=($(grep '^cpu ' /proc/stat))
IDLE_CUR=${CPU_CUR[4]}
TOTAL_CUR=0
for i in "${CPU_CUR[@]:1}"; do
    TOTAL_CUR=$((TOTAL_CUR + i))
done

if [ -f "$CPU_FILE" ]; then
    read TOTAL_PREV IDLE_PREV < "$CPU_FILE"
else
    TOTAL_PREV=$TOTAL_CUR
    IDLE_PREV=$IDLE_CUR
fi

DIFF_IDLE=$((IDLE_CUR - IDLE_PREV))
DIFF_TOTAL=$((TOTAL_CUR - TOTAL_PREV))
CPU_USAGE=$((DIFF_TOTAL ? 100 * (DIFF_TOTAL - DIFF_IDLE) / DIFF_TOTAL : 0))
echo "$TOTAL_CUR $IDLE_CUR" > "$CPU_FILE"

CPU_TEXT=$(printf "%3s%%" "$CPU_USAGE")

if [ "$ONCLICK" = "true" ]; then
    echo -n "$CPU_TEXT" | wl-copy
else
    echo "{\"text\": \"CPU: $CPU_TEXT\"}"
fi
