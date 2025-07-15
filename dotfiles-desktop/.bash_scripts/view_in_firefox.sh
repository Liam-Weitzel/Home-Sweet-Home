#!/bin/bash

INPUT=$(echo "$1" | sed "s/^['\"]//; s/['\"]$//")
MIME_TYPE="$2"

# If MIME_TYPE is a wildcard image type, try to guess a precise type from file extension
if [[ "$MIME_TYPE" == image/* ]]; then
  EXT="${INPUT##*.}"
  case "$EXT" in
    png)  MIME_TYPE="image/png" ;;
    jpg|jpeg) MIME_TYPE="image/jpeg" ;;
    gif)  MIME_TYPE="image/gif" ;;
    svg)  MIME_TYPE="image/svg+xml" ;;
    webp) MIME_TYPE="image/webp" ;;
    bmp)  MIME_TYPE="image/bmp" ;;
    tiff|tif) MIME_TYPE="image/tiff" ;;
    *) MIME_TYPE="image/png" ;;  # fallback for unknown extensions
  esac
fi

if [[ -f "$INPUT" ]]; then
  FILE_BASENAME=$(basename "$INPUT")
  URI="http://localhost:8000/$FILE_BASENAME?mime=$(printf '%s' "$MIME_TYPE" | jq -s -R -r @uri)"
elif [[ "$INPUT" =~ ^(https?|file):// ]]; then
  URI="$INPUT"
else
  URI="https://$INPUT"
fi

ENCODED_URI=$(printf '%s' "$URI" | jq -s -R -r @uri)

EXTENSION_URL="moz-extension://151b039a-85b6-4372-9efd-d1279064176e/ssb.html"
FULL_URL="${EXTENSION_URL}?url=${ENCODED_URI}&name=&incognito=false"

firefox --name=ssb -P ssb --new-window "$FULL_URL" &
