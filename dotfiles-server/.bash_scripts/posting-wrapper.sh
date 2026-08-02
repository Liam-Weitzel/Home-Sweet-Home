#!/usr/bin/env bash
set -o emacs
echo "Enter file path to collection"
echo "Use Tab for completion"
read -e -r path
path="${path/#\~/$HOME}"
if [ ! -e "$path" ]; then
    posting
    exit 1
fi
posting --collection "$path"
