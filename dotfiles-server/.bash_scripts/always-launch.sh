#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <command> <process_name>"
    exit 1
fi

COMMAND="$1"
PROCESS="$2"

while true; do
    if ! pgrep -x "$PROCESS" > /dev/null; then
        echo "Starting $PROCESS..."
        $COMMAND &
    fi
    sleep 1
done
