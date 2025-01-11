#!/bin/bash

TEXT=${1:-"std::"}
CURSOR_STEPS=${2:-0}
LEFT_STEPS=${3:-0}
RIGHT_STEPS=${4:-0}
USE_TYPING=${5:-0}
BACKSPACE_COUNT=${6:-0}
TEMP_FILE="/tmp/capitalize_next"

[[ ! "$BACKSPACE_COUNT" =~ ^[0-9]+$ ]] && BACKSPACE_COUNT=0
[[ ! "$LEFT_STEPS" =~ ^[0-9]+$ ]] && LEFT_STEPS=0
[[ ! "$CURSOR_STEPS" =~ ^[0-9]+$ ]] && CURSOR_STEPS=0
[[ ! "$RIGHT_STEPS" =~ ^[0-9]+$ ]] && RIGHT_STEPS=0

capitalize=$([[ -f $TEMP_FILE ]] && cat $TEMP_FILE || echo 0)

if [[ $capitalize -eq 1 ]]; then
    text=$(echo "$TEXT" | sed 's/./\u&/')
else
    text="$TEXT"
fi

type_mode() {
    local cmd=()
    
    for ((i=0; i<BACKSPACE_COUNT; i++)); do cmd+=(-k backspace); done
    for ((i=0; i<LEFT_STEPS; i++)); do cmd+=(-k left); done
    cmd+=("$text")
    for ((i=0; i<CURSOR_STEPS; i++)); do cmd+=(-k left); done
    for ((i=0; i<RIGHT_STEPS; i++)); do cmd+=(-k right); done
    
    wtype "${cmd[@]}"
}

just_text() {
    wtype -- "$text"
}

clipboard_mode() {
    local previous=$(wl-paste)
    local cmd=()
    
    for ((i=0; i<BACKSPACE_COUNT; i++)); do cmd+=(-k backspace); done
    for ((i=0; i<LEFT_STEPS; i++)); do cmd+=(-k left); done
    cmd+=(-M ctrl -M shift v -m ctrl -m shift)
    for ((i=0; i<CURSOR_STEPS; i++)); do cmd+=(-k left); done
    for ((i=0; i<RIGHT_STEPS; i++)); do cmd+=(-k right); done

    echo -n "$text" | wl-copy
    wtype "${cmd[@]}"
    {
        cliphist delete-query "$text"
        echo -n "$previous" | wl-copy
    } &
}


if [ "$USE_TYPING" -eq 1 ]; then
    if (( $RIGHT_STEPS + $CURSOR_STEPS + $LEFT_STEPS + $BACKSPACE_COUNT > 0 )); then
	type_mode
    else
	just_text
    fi
else
    clipboard_mode
fi
echo 0 > $TEMP_FILE
