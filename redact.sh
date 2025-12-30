#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOKENS_FILE="$SCRIPT_DIR/.tokens"
MAPPING_FILE="$SCRIPT_DIR/.redact_mapping"
BACKUP_DIR="$SCRIPT_DIR/.redact_backup"

usage() {
    echo "Usage: $0 [redact|unredact]"
    echo "  redact   - Replace tokens with REDACTED placeholders"
    echo "  unredact - Restore original tokens from placeholders"
    echo ""
    echo "Tokens should be listed in .tokens file (one per line)"
    exit 1
}

create_backup() {
    echo "Creating backup..."
    rm -rf "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Find all files (excluding obvious binaries and system directories)
    find . -type f \
        ! -path "./.git/*" \
        ! -path "./.redact_backup/*" \
        ! -name "redact.sh" \
        ! -name ".redact_mapping" \
        ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.png" ! -name "*.gif" ! -name "*.bmp" \
        ! -name "*.mp4" ! -name "*.mp3" ! -name "*.avi" ! -name "*.mkv" ! -name "*.wav" \
        ! -name "*.pdf" ! -name "*.zip" ! -name "*.tar" ! -name "*.gz" ! -name "*.bz2" \
        ! -name "*.exe" ! -name "*.bin" ! -name "*.so" ! -name "*.dll" | \
    while read -r file; do
        backup_path="$BACKUP_DIR/${file#./}"
        mkdir -p "$(dirname "$backup_path")"
        cp "$file" "$backup_path"
    done
}

restore_backup() {
    echo "Restoring from backup..."
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "Error: No backup directory found. Cannot unredact."
        exit 1
    fi

    find "$BACKUP_DIR" -type f | while read -r backup_file; do
        original_file="${backup_file#$BACKUP_DIR/}"
        if [[ -f "$original_file" ]]; then
            cp "$backup_file" "$original_file"
        fi
    done
}

read_tokens() {
    if [[ ! -f "$TOKENS_FILE" ]]; then
        echo "Error: $TOKENS_FILE not found. Please create it with your tokens (one per line)."
        exit 1
    fi

    grep -v '^#' "$TOKENS_FILE" | grep -v '^[[:space:]]*$' || true
}

redact_tokens() {
    echo "Starting redaction process..."
    create_backup

    > "$MAPPING_FILE"  # Clear mapping file

    local counter=1
    read_tokens | while read -r token; do
        if [[ -z "$token" ]]; then
            continue
        fi

        placeholder="REDACTED$(printf "%03d" $counter)"
        echo "$placeholder=$token" >> "$MAPPING_FILE"

        echo "Redacting token $counter..."

        # Find and replace in all files
        find . -type f \
            ! -path "./.git/*" \
            ! -path "./.redact_backup/*" \
            ! -name "redact.sh" \
            ! -name ".redact_mapping" \
            ! -name ".tokens" \
            ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.png" ! -name "*.gif" ! -name "*.bmp" \
            ! -name "*.mp4" ! -name "*.mp3" ! -name "*.avi" ! -name "*.mkv" ! -name "*.wav" \
            ! -name "*.pdf" ! -name "*.zip" ! -name "*.tar" ! -name "*.gz" ! -name "*.bz2" \
            ! -name "*.exe" ! -name "*.bin" ! -name "*.so" ! -name "*.dll" | \
        while read -r file; do
            if grep -l "$token" "$file" 2>/dev/null; then
                sed -i "s|$token|$placeholder|g" "$file"
                echo "  Redacted in: $file"
            fi
        done

        ((counter++))
    done

    echo "Redaction complete. Mapping saved to $MAPPING_FILE"
}

unredact_tokens() {
    echo "Starting unredaction process..."

    if [[ ! -f "$MAPPING_FILE" ]]; then
        echo "Error: No mapping file found. Cannot unredact."
        echo "Attempting to restore from backup..."
        restore_backup
        rm -rf "$BACKUP_DIR"
        echo "Backup restored."
        return
    fi

    while IFS='=' read -r placeholder token; do
        if [[ -n "$placeholder" && -n "$token" ]]; then
            echo "Unredacting $placeholder..."

            # Find and replace placeholders with original tokens
            find . -type f \
                ! -path "./.git/*" \
                ! -path "./.redact_backup/*" \
                ! -name "redact.sh" \
                ! -name ".redact_mapping" \
                ! -name ".tokens" \
                ! -name "*.jpg" ! -name "*.jpeg" ! -name "*.png" ! -name "*.gif" ! -name "*.bmp" \
                ! -name "*.mp4" ! -name "*.mp3" ! -name "*.avi" ! -name "*.mkv" ! -name "*.wav" \
                ! -name "*.pdf" ! -name "*.zip" ! -name "*.tar" ! -name "*.gz" ! -name "*.bz2" \
                ! -name "*.exe" ! -name "*.bin" ! -name "*.so" ! -name "*.dll" | \
            while read -r file; do
                if grep -l "$placeholder" "$file" 2>/dev/null; then
                    sed -i "s|$placeholder|$token|g" "$file"
                    echo "  Unredacted in: $file"
                fi
            done
        fi
    done < "$MAPPING_FILE"

    # Clean up
    rm -f "$MAPPING_FILE"
    rm -rf "$BACKUP_DIR"
    echo "Unredaction complete."
}

main() {
    if [[ $# -ne 1 ]]; then
        usage
    fi

    case "$1" in
        "redact")
            redact_tokens
            ;;
        "unredact")
            unredact_tokens
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
