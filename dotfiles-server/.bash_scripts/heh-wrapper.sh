#!/usr/bin/env bash
set -o emacs
echo "Enter file path to view in hex editor:"
echo "Use Tab for completion"
read -e -r file
file="${file/#\~/$HOME}"
if [ -z "$file" ]; then
    echo "No file specified!"
    read -p "Press Enter to exit..."
    exit 1
fi
if [ ! -f "$file" ]; then
    echo "File does not exist: $file"
    read -p "Press Enter to exit..."
    exit 1
fi
heh "$file"