#!/usr/bin/env bash
set -o emacs
echo "Enter directory/file path to analyze (or press Enter for current directory):"
echo "Use Tab for completion"
read -e -r path
if [ -z "$path" ]; then
    path="."
fi
path="${path/#\~/$HOME}"
if [ ! -e "$path" ]; then
    echo "Path does not exist: $path"
    read -p "Press Enter to exit..."
    exit 1
fi
echo "Analyzing: $path"
cloc "$path"
echo
read -p "Press Enter to exit..."