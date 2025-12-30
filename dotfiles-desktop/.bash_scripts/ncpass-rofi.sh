#!/usr/bin/env bash

# ncpass-rofi - Rofi front-end for ncpass
# This script provides a graphical interface for the ncpass CLI tool

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NCPASS_CLI="$HOME/.bash_scripts/ncpass.sh"

# Set up temp directory for persistent state - use a fixed name so it persists across sessions
TEMP_DIR="${TMPDIR:-/tmp}/ncpass-rofi-persistent"
mkdir -p "$TEMP_DIR"
FORM_STATE_FILE="$TEMP_DIR/form_state.tmp"
SESSION_STATE_FILE="$TEMP_DIR/session_state.tmp"
ACCOUNT_LIST_CACHE="$TEMP_DIR/account_list_cache.tmp"
ACCOUNT_DATA_CACHE="$TEMP_DIR/account_data_cache.json"
CACHE_TIMESTAMP="$TEMP_DIR/cache_timestamp"

# Don't cleanup on exit - we want persistence!

# Check if ncpass CLI exists
if [[ ! -f "$NCPASS_CLI" ]]; then
    rofi -e "ncpass CLI not found at $NCPASS_CLI"
    exit 1
fi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Please install rofi first."
    exit 1
fi

# Environment variables are now hardcoded in ncpass.sh - no need to check

# Function to check if cache is valid (less than 30 minutes old)
is_cache_valid() {
    if [[ -f "$CACHE_TIMESTAMP" ]]; then
        local cache_time
        cache_time=$(cat "$CACHE_TIMESTAMP")
        local current_time
        current_time=$(date +%s)
        local age=$((current_time - cache_time))
        # Cache valid for 10 hours (36000 seconds)
        [[ $age -lt 36000 ]]
    else
        return 1
    fi
}

# Function to refresh cache
refresh_cache() {
    echo $(date +%s) > "$CACHE_TIMESTAMP"
    get_password_list_fresh > "$ACCOUNT_LIST_CACHE"
}

# Function to get cached account list
get_cached_account_list() {
    if [[ -f "$ACCOUNT_LIST_CACHE" ]] && is_cache_valid; then
        cat "$ACCOUNT_LIST_CACHE"
    else
        # Cache miss or expired - refresh and return
        refresh_cache
        cat "$ACCOUNT_LIST_CACHE"
    fi
}

# Function to get cached account data for a specific label
get_cached_account_data() {
    local label="$1"
    local cache_key
    cache_key=$(echo -n "$label" | md5sum | cut -d' ' -f1)
    local cache_file="$TEMP_DIR/account_${cache_key}.json"

    # Check if we have cached data and cache is valid
    if [[ -f "$cache_file" ]] && is_cache_valid; then
        cat "$cache_file"
    else
        # Cache miss or expired - fetch fresh data and cache it
        local account_data
        account_data=$("$NCPASS_CLI" getall "$label" 2>/dev/null || echo "{}")
        echo "$account_data" > "$cache_file"
        echo "$account_data"
    fi
}

# Function to prefetch account data in background
prefetch_account_data() {
    local label="$1"
    (
        # Background prefetch - don't block UI
        get_cached_account_data "$label" > /dev/null 2>&1
    ) &
}

# Function to invalidate cache for a specific account
invalidate_account_cache() {
    local label="$1"
    local cache_key
    cache_key=$(echo -n "$label" | md5sum | cut -d' ' -f1)
    local cache_file="$TEMP_DIR/account_${cache_key}.json"
    rm -f "$cache_file"
    # Also invalidate the main account list cache
    rm -f "$ACCOUNT_LIST_CACHE"
}

# Function to show account selection with create option
show_account_selection() {
    local password_list
    password_list=$(get_cached_account_list)

    local options="🆕 Create new password\n🔄 Refresh password list"
    if [[ -n "$password_list" ]]; then
        options="$options\n$password_list"
    fi

    echo -e "$options" | rofi -dmenu -i -p "Select account:" -theme-str 'window {width: 600px;}'
}

# Function to get password list for selection (fresh from API)
get_password_list_fresh() {
    "$NCPASS_CLI" list 2>/dev/null | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            echo "$line"
        fi
    done
}

# Function to copy to clipboard with notification
copy_to_clipboard() {
    local content="$1"
    local description="$2"

    if command -v xclip &> /dev/null; then
        echo -n "$content" | xclip -selection clipboard
    elif command -v wl-copy &> /dev/null; then
        echo -n "$content" | wl-copy
    else
        rofi -e "No clipboard tool found (xclip or wl-copy needed)"
        return 1
    fi

    # Show notification
    # if command -v notify-send &> /dev/null; then
    #     notify-send "NCPass" "$description copied to clipboard" -t 3000
    # fi
}

# Function to show action menu for selected account
show_action_menu() {
    local account="$1"
    local options="🔐 Copy password
👤 Copy username
🌐 Copy website
📝 Copy notes
✏️  Edit account
🗑️  Delete account
❌ Back"

    echo "$options" | rofi -dmenu -i -p "$account - Choose action:" -theme-str 'window {width: 400px;}'
}

# Function to handle account actions
handle_account_action() {
    local selected_account="$1"
    local action="$2"

    # Selected account is now just the label (no username in list)
    local label="$selected_account"

    case "$action" in
        "🔐 Copy password")
            local password
            password=$("$NCPASS_CLI" get "$label" 2>/dev/null)

            if [[ -n "$password" ]]; then
                copy_to_clipboard "$password" "Password for $label"
            else
                rofi -e "Failed to retrieve password for $label"
            fi
            ;;
        "👤 Copy username")
            local user
            user=$("$NCPASS_CLI" getuser "$label" 2>/dev/null)
            if [[ -n "$user" ]]; then
                copy_to_clipboard "$user" "Username for $label"
            else
                rofi -e "No username found for $label"
            fi
            ;;
        "🌐 Copy website")
            local url
            url=$("$NCPASS_CLI" geturl "$label" 2>/dev/null)
            if [[ -n "$url" ]]; then
                copy_to_clipboard "$url" "Website for $label"
            else
                rofi -e "No website found for $label"
            fi
            ;;
        "📝 Copy notes")
            local notes
            notes=$("$NCPASS_CLI" getnotes "$label" 2>/dev/null)
            if [[ -n "$notes" ]]; then
                copy_to_clipboard "$notes" "Notes for $label"
            else
                rofi -e "No notes found for $label"
            fi
            ;;
        "✏️  Edit account")
            edit_existing_account "$selected_account" || true
            ;;
        "🗑️  Delete account")
            local confirm
            confirm=$(echo -e "No\nYes" | rofi -dmenu -p "Delete account '$label'?")
            if [[ "$confirm" == "Yes" ]]; then
                local delete_result exit_code
                delete_result=$("$NCPASS_CLI" delete "$label" 2>&1)
                exit_code=$?

                if [[ $exit_code -eq 0 ]]; then
                    invalidate_account_cache "$label"
                    rofi -e "Account '$label' deleted successfully"
                else
                    rofi -e "Failed to delete account: $delete_result"
                fi
            fi
            ;;
    esac
}

# Function to save form state
save_form_state() {
    local label="$1" username="$2" password="$3" url="$4" notes="$5" generate_password="$6"
    cat > "$FORM_STATE_FILE" << EOF
label=$(printf '%q' "$label")
username=$(printf '%q' "$username")
password=$(printf '%q' "$password")
url=$(printf '%q' "$url")
notes=$(printf '%q' "$notes")
generate_password=$generate_password
EOF
}

# Function to load form state
load_form_state() {
    if [[ -f "$FORM_STATE_FILE" ]]; then
        source "$FORM_STATE_FILE"
    else
        label=""
        username=""
        password=""
        url=""
        notes=""
        generate_password=false
    fi
}

# Function to clear form state
clear_form_state() {
    rm -f "$FORM_STATE_FILE"
}

# Function to save session state (what screen we're on)
save_session_state() {
    local screen="$1"
    local selected_account="$2"
    cat > "$SESSION_STATE_FILE" << EOF
current_screen='$screen'
selected_account='$selected_account'
EOF
}

# Function to load session state
load_session_state() {
    if [[ -f "$SESSION_STATE_FILE" ]]; then
        source "$SESSION_STATE_FILE"
    else
        current_screen="main"
        selected_account=""
    fi
}

# Function to clear session state
clear_session_state() {
    rm -f "$SESSION_STATE_FILE"
}

# Function to show editable form for account
show_account_form() {
    local mode="$1"  # "create" or "edit"
    local existing_label="$2"
    local selected_account="$3"  # For saving session state in edit mode

    # Get existing values if editing
    local current_url current_notes current_username current_password
    if [[ "$mode" == "edit" ]]; then
        local account_data
        account_data=$(get_cached_account_data "$existing_label")
        current_url=$(echo "$account_data" | jq -r '.url // ""' 2>/dev/null || echo "")
        current_notes=$(echo "$account_data" | jq -r '.notes // ""' 2>/dev/null || echo "")
        current_username=$(echo "$account_data" | jq -r '.username // ""' 2>/dev/null || echo "")
        current_password=$(echo "$account_data" | jq -r '.password // ""' 2>/dev/null || echo "")
    fi

    # Load persistent state or initialize form values
    if [[ "$mode" == "create" ]]; then
        load_form_state
    else
        # For edit mode, check if we have saved state first, otherwise use existing values
        if [[ -f "$FORM_STATE_FILE" ]]; then
            load_form_state
            # Only override label with existing value if no saved label exists
            if [[ -z "$label" ]]; then
                label="$existing_label"
            fi
            # If username is empty in saved state, use existing
            if [[ -z "$username" ]]; then
                username="$current_username"
            fi
            # If url/notes are empty in saved state, use existing values
            if [[ -z "$url" ]]; then
                url="$current_url"
            fi
            if [[ -z "$notes" ]]; then
                notes="$current_notes"
            fi
            # If password is empty in saved state, use existing password
            if [[ -z "$password" ]]; then
                password="$current_password"
            fi
        else
            # No saved state, start with existing values
            label="${existing_label:-}"
            username="${current_username:-}"
            password="${current_password:-}"
            url="${current_url:-}"
            notes="${current_notes:-}"
            generate_password=false
        fi
    fi

    while true; do
        local form_display
        if [[ "$mode" == "edit" ]]; then
            form_display="📝 Label: ${label} (read-only)
👤 Username: ${username:-"(optional)"}
🔐 Password: ${password:-"(optional)"}
🎲 Generate random password: $(if [[ "$generate_password" == "true" ]]; then echo "✅"; else echo "❌"; fi)
🌐 URL: ${url:-"(optional)"}
📄 Notes: ${notes:-"(optional)"}
────────────────────
💾 Save account
❌ Back"
        else
            form_display="📝 Label: ${label:-"(required)"}
👤 Username: ${username:-"(optional)"}
🔐 Password: ${password:-"(optional)"}
🎲 Generate random password: $(if [[ "$generate_password" == "true" ]]; then echo "✅"; else echo "❌"; fi)
🌐 URL: ${url:-"(optional)"}
📄 Notes: ${notes:-"(optional)"}
────────────────────
💾 Save account
❌ Back"
        fi

        local choice
        choice=$(echo -e "$form_display" | rofi -dmenu -i -p "${mode^} Account Form:" -theme-str 'window {width: 500px;}')

        case "$choice" in
            *"Label:"*)
                if [[ "$mode" == "create" ]]; then
                    local new_label
                    new_label=$(rofi -dmenu -p "Enter label:" -filter "$label" -theme-str 'window {width: 400px;}')
                    if [[ -n "$new_label" ]]; then
                        label="$new_label"
                    fi
                    save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                else
                    # In edit mode, label is read-only - show message
                    rofi -e "Label cannot be changed (it's the primary key)"
                fi
                ;;
            *"Username:"*)
                local new_username
                new_username=$(rofi -dmenu -p "Enter username:" -filter "$username" -theme-str 'window {width: 400px;}')
                username="$new_username"
                save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                ;;
            *"Password:"*)
                local new_password
                new_password=$(rofi -dmenu -password -p "Enter password:" -theme-str 'window {width: 400px;}')
                if [[ -n "$new_password" ]]; then
                    password="$new_password"
                    generate_password=false
                fi
                save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                ;;
            *"Generate random password:"*)
                if [[ "$generate_password" == true ]]; then
                    generate_password=false
                    password=""
                else
                    generate_password=true
                    password=""
                fi
                save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                ;;
            *"URL:"*)
                local new_url
                new_url=$(rofi -dmenu -p "Enter URL:" -filter "$url" -theme-str 'window {width: 400px;}')
                url="$new_url"
                save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                ;;
            *"Notes:"*)
                local new_notes
                new_notes=$(rofi -dmenu -p "Enter notes:" -filter "$notes" -theme-str 'window {width: 400px;}')
                notes="$new_notes"
                save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                ;;
            *"Save account")
                # Validate required fields
                if [[ -z "$label" ]]; then
                    rofi -e "Label is required!"
                    continue
                fi

                if [[ "$generate_password" == false && -z "$password" && "$mode" == "create" ]]; then
                    rofi -e "Password is required for new accounts! Either enter a password or enable 'Generate random password'."
                    continue
                fi

                # Execute save
                if save_account "$mode" "$label" "$username" "$password" "$url" "$notes" "$generate_password"; then
                    clear_form_state
                    # Invalidate cache after successful save
                    invalidate_account_cache "$label"
                    if [[ "$mode" == "edit" ]]; then
                        # For edit, save session to return to action menu on next startup
                        save_session_state "action_menu" "$selected_account"
                        exit 0
                    else
                        # For create, clear session to return to main menu on next startup
                        clear_session_state
                        exit 0
                    fi
                else
                    return 1
                fi
                ;;
            *"Back")
                clear_form_state
                if [[ "$mode" == "edit" ]]; then
                    # For edit, signal back button was pressed
                    return 1
                else
                    # For create, clear session to return to main menu
                    clear_session_state
                    return 0
                fi
                ;;
            "")
                # Empty selection (escape pressed)
                if [[ "$mode" == "edit" ]]; then
                    # For edit, save current form state and set session to resume editing
                    save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                    save_session_state "edit_form" "$selected_account"
                    exit 0
                else
                    # For create, save current form state and set session to resume creating
                    save_form_state "$label" "$username" "$password" "$url" "$notes" "$generate_password"
                    save_session_state "create_form" ""
                    exit 0
                fi
                ;;
        esac
    done
}

# Function to save account
save_account() {
    local mode="$1"
    local label="$2"
    local username="$3"
    local password="$4"
    local url="$5"
    local notes="$6"
    local generate_password="$7"

    local cmd result

    if [[ "$generate_password" == true ]]; then
        # Generate password
        cmd=("$NCPASS_CLI" "generate" "$label")
        if [[ -n "$username" ]]; then
            cmd+=("$username")
        fi
        if [[ -n "$url" ]]; then
            cmd+=("--url" "$url")
        fi
        if [[ -n "$notes" ]]; then
            cmd+=("--notes" "$notes")
        fi

        result=$("${cmd[@]}" 2>/dev/null)
        local exit_code=$?

        if [[ $exit_code -eq 0 && -n "$result" ]]; then
            copy_to_clipboard "$result" "Generated password for $label"
            rofi -e "Account '$label' saved with generated password!"
            return 0
        else
            rofi -e "Failed to generate password."
            return 1
        fi
    else
        # Set custom password (or update without changing password if empty)
        cmd=("$NCPASS_CLI" "set" "$label")
        if [[ -n "$username" && -n "$password" ]]; then
            cmd+=("$username" "$password")
        elif [[ -n "$password" ]]; then
            cmd+=("$password")
        elif [[ "$mode" == "edit" && -n "$username" ]]; then
            # For edit mode without password change, we need to preserve existing password
            cmd+=("$username")
        fi
        if [[ -n "$url" ]]; then
            cmd+=("--url" "$url")
        fi
        if [[ -n "$notes" ]]; then
            cmd+=("--notes" "$notes")
        fi

        "${cmd[@]}" 2>/dev/null
        local exit_code=$?

        if [[ $exit_code -eq 0 ]]; then
            if [[ -n "$password" ]]; then
                copy_to_clipboard "$password" "Password for $label"
            fi
            rofi -e "Account '$label' ${mode}d successfully!"
            return 0
        else
            rofi -e "Failed to save account."
            return 1
        fi
    fi
}


# Function to create new password
create_new_password() {
    save_session_state "create_form" ""
    if show_account_form "create"; then
        # Form was saved successfully
        clear_session_state
    else
        # Form was cancelled with back button - keep session state for persistence
        # Don't clear session state so it can be resumed
        :
    fi
}

# Function to edit existing account
edit_existing_account() {
    local selected_account="$1"
    local label="$selected_account"

    save_session_state "edit_form" "$selected_account"
    if show_account_form "edit" "$label" "$selected_account"; then
        # Form was saved successfully - return to action menu
        save_session_state "action_menu" "$selected_account"
        return 0
    else
        # Form was cancelled with back button - clear session to go to main menu
        clear_session_state
        return 1
    fi
}


# Main execution
main() {
    # Check if we should restore a previous session
    load_session_state

    if [[ "$current_screen" == "create_form" ]] && [[ -f "$FORM_STATE_FILE" ]]; then
        # Resume the create form
        create_new_password
        # Don't return - let it fall through to normal main loop
    elif [[ "$current_screen" == "action_menu" ]] && [[ -n "$selected_account" ]]; then
        # Resume the action menu for the selected account
        show_action_menu_loop "$selected_account"
        # Don't return - let it fall through to normal main loop
    elif [[ "$current_screen" == "edit_form" ]] && [[ -n "$selected_account" ]]; then
        # Resume editing - preserve form state and call form directly
        local label="$selected_account"

        # Call show_account_form directly to preserve saved form state
        if show_account_form "edit" "$label" "$selected_account"; then
            # Form was saved successfully - clear session and exit
            clear_session_state
            exit 0
        else
            # Form was cancelled with back - continue to main menu
            clear_session_state
        fi
    fi

    while true; do
        local selected_account
        selected_account=$(show_account_selection)

        if [[ -z "$selected_account" ]]; then
            clear_session_state
            exit 0  # User cancelled
        fi

        if [[ "$selected_account" == "🆕 Create new password" ]]; then
            create_new_password
            continue
        fi

        if [[ "$selected_account" == "🔄 Refresh password list" ]]; then
            refresh_cache
            continue
        fi

        # Selected account is now just the label
        local label="$selected_account"

        # Start background prefetch of account data
        prefetch_account_data "$label"

        # Show action menu for selected account
        show_action_menu_loop "$selected_account"
        # If action menu returns (Back button), continue main loop
    done
}

# Function to handle the action menu loop with persistence
show_action_menu_loop() {
    local selected_account="$1"
    save_session_state "action_menu" "$selected_account"

    while true; do
        local action
        action=$(show_action_menu "$selected_account")

        if [[ -z "$action" || "$action" == "❌ Back" ]]; then
            clear_session_state
            break  # Go back to account selection
        fi

        handle_account_action "$selected_account" "$action"

        # For copy operations, keep session state and exit rofi
        # For delete operations, clear state and exit rofi
        # For edit operations, the action may have set session to return to action menu
        if [[ "$action" == "🔐 Copy password" || "$action" == "👤 Copy username" || "$action" == "🌐 Copy website" || "$action" == "📝 Copy notes" ]]; then
            # Keep session state so we return to this account's menu on restart
            exit 0
        elif [[ "$action" == "🗑️  Delete account" ]]; then
            # Clear session state and exit rofi after deletion
            clear_session_state
            exit 0
        elif [[ "$action" == "✏️  Edit account" ]]; then
            # Edit is handled in handle_account_action
            # Check if session was cleared (back button pressed)
            load_session_state
            if [[ "$current_screen" != "action_menu" ]]; then
                break
            else
                continue
            fi
        else
            # This shouldn't happen, but just in case
            break
        fi
    done
}

# Check if running directly or being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
