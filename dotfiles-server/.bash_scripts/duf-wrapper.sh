#!/usr/bin/env bash
set -o emacs
echo "Enter directory path (or press Enter for current directory):"
echo "Use Tab for completion"
read -e -r dir
if [ -z "$dir" ]; then
    dir="."
fi
dir="${dir/#\~/$HOME}"
cd "$dir" 2>/dev/null || { echo "Invalid directory: $dir"; read -p "Press Enter to exit..."; exit 1; }
duf
echo
read -p "Press Enter to exit..."