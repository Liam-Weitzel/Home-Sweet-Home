#!/usr/bin/env bash

# ncotp-rofi - Rofi front-end for ncotp
# This script provides a graphical interface for the ncotp CLI tool

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NCOTP_CLI="$SCRIPT_DIR/ncotp.sh"

# Set up temp directory for persistent state - use a fixed name so it persists across sessions
TEMP_DIR="${TMPDIR:-/tmp}/ncotp-rofi-persistent"
mkdir -p "$TEMP_DIR"
FORM_STATE_FILE="$TEMP_DIR/form_state.tmp"
SESSION_STATE_FILE="$TEMP_DIR/session_state.tmp"
ACCOUNT_LIST_CACHE="$TEMP_DIR/account_list_cache.tmp"
ACCOUNT_DATA_CACHE="$TEMP_DIR/account_data_cache.json"
CACHE_TIMESTAMP="$TEMP_DIR/cache_timestamp"

# Don't cleanup on exit - we want persistence!

# Check if ncotp CLI exists
if [[ ! -f "$NCOTP_CLI" ]]; then
    rofi -e "ncotp CLI not found at $NCOTP_CLI"
    exit 1
fi

# Check if rofi is installed
if ! command -v rofi &> /dev/null; then
    echo "Error: rofi is not installed. Please install rofi first."
    exit 1
fi

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
    get_account_list_fresh > "$ACCOUNT_LIST_CACHE"
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

# Function to get cached account data for a specific account
get_cached_account_data() {
    local name="$1"
    local issuer="$2"
    local cache_key
    cache_key=$(echo -n "${name}_${issuer}" | md5sum | cut -d' ' -f1)
    local cache_file="$TEMP_DIR/account_${cache_key}.json"

    # Check if we have cached data and cache is valid
    if [[ -f "$cache_file" ]] && is_cache_valid; then
        cat "$cache_file"
    else
        # Cache miss or expired - fetch fresh data and cache it
        local account_data
        account_data=$("$NCOTP_CLI" get "$name" "$issuer" 2>/dev/null || echo "{}")
        echo "$account_data" > "$cache_file"
        echo "$account_data"
    fi
}

# Function to get cached action data (account details + OTP + timing) for action menu
get_cached_action_data() {
    local name="$1"
    local issuer="$2"
    local cache_key
    cache_key=$(echo -n "action_${name}_${issuer}" | md5sum | cut -d' ' -f1)
    local cache_file="$TEMP_DIR/action_${cache_key}.json"

    # For action data, use shorter cache (5 minutes for OTP codes)
    local action_cache_valid=false
    if [[ -f "$cache_file" ]]; then
        local cache_time
        cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        local current_time
        current_time=$(date +%s)
        local age=$((current_time - cache_time))
        # Action cache valid for 5 minutes (300 seconds) due to OTP timing
        [[ $age -lt 300 ]] && action_cache_valid=true
    fi

    if [[ -f "$cache_file" ]] && [[ "$action_cache_valid" == true ]]; then
        cat "$cache_file"
    else
        # Cache miss or expired - fetch fresh data and cache it
        local action_data
        action_data=$("$NCOTP_CLI" action-data "$name" "$issuer" 2>/dev/null || echo "{}")
        echo "$action_data" > "$cache_file"
        echo "$action_data"
    fi
}

# Function to prefetch account data in background
prefetch_account_data() {
    local name="$1"
    local issuer="$2"
    (
        # Background prefetch - don't block UI
        get_cached_account_data "$name" "$issuer" > /dev/null 2>&1
    ) &
}

# Function to prefetch action data in background
prefetch_action_data() {
    local name="$1"
    local issuer="$2"
    (
        # Background prefetch - don't block UI
        get_cached_action_data "$name" "$issuer" > /dev/null 2>&1
    ) &
}

# Function to invalidate cache for a specific account
invalidate_account_cache() {
    local name="$1"
    local issuer="$2"
    local cache_key
    cache_key=$(echo -n "${name}_${issuer}" | md5sum | cut -d' ' -f1)
    local cache_file="$TEMP_DIR/account_${cache_key}.json"
    rm -f "$cache_file"

    # Also invalidate action data cache
    local action_cache_key
    action_cache_key=$(echo -n "action_${name}_${issuer}" | md5sum | cut -d' ' -f1)
    local action_cache_file="$TEMP_DIR/action_${action_cache_key}.json"
    rm -f "$action_cache_file"

    # Also invalidate the main account list cache
    rm -f "$ACCOUNT_LIST_CACHE"
}

# Function to show account selection with create option
show_account_selection() {
    local account_list
    account_list=$(get_cached_account_list)

    local options="🆕 Create new OTP account\n🔄 Refresh account list"
    if [[ -n "$account_list" ]]; then
        options="$options\n────────────────────────────"
        # Format accounts without emojis (cleaner look)
        local formatted_accounts
        formatted_accounts=$(echo "$account_list" | while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local name issuer
                name=$(echo "$line" | jq -r '.name')
                issuer=$(echo "$line" | jq -r '.issuer')

                echo "$name ($issuer)"
            fi
        done)

        if [[ -n "$formatted_accounts" ]]; then
            options="$options\n$formatted_accounts"
        fi
    fi

    echo -e "$options" | rofi -dmenu -i -p "Select OTP account:" -theme-str 'window {width: 600px;}'
}

# Function to get account list for selection (fresh from API)
get_account_list_fresh() {
    "$NCOTP_CLI" list 2>/dev/null | jq -c '.'
}

# Function to parse account selection back to name/issuer
parse_account_selection() {
    local selection="$1"
    # Extract name and issuer from format: "name (issuer)"
    local regex='^(.+)[[:space:]]+\(([^)]+)\)$'
    if [[ "$selection" =~ $regex ]]; then
        selected_account_name="${BASH_REMATCH[1]}"
        selected_account_issuer="${BASH_REMATCH[2]}"
        return 0
    else
        return 1
    fi
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

    # No notification - copying should be silent
}

# Function to calculate current time remaining for TOTP
calculate_current_time_remaining() {
    local period="$1"
    local original_time="$2"
    local fetch_timestamp="$3"

    local current_time=$(date +%s)
    local elapsed_since_fetch=$((current_time - fetch_timestamp))
    local adjusted_remaining=$((original_time - elapsed_since_fetch))

    # If time has expired, return 0 to signal cache invalidation needed
    if [[ $adjusted_remaining -le 0 ]]; then
        echo 0
    else
        echo $adjusted_remaining
    fi
}

# Function to show action menu with dynamic timer support
show_action_menu() {
    local account_name="$1"
    local issuer="$2"

    # Get unified action data (account + OTP + timing)
    local action_data
    action_data=$(get_cached_action_data "$account_name" "$issuer")

    local type=$(echo "$action_data" | jq -r '.type')
    local otp_code=$(echo "$action_data" | jq -r '.otp_code')
    local time_remaining=$(echo "$action_data" | jq -r '.time_remaining // "null"')
    local period=$(echo "$action_data" | jq -r '.period // 30')

    # For TOTP, calculate current time remaining from cache timestamp
    if [[ "$type" == "totp" && "$time_remaining" != "null" ]]; then
        local action_cache_key
        action_cache_key=$(echo -n "action_${account_name}_${issuer}" | md5sum | cut -d' ' -f1)
        local action_cache_file="$TEMP_DIR/action_${action_cache_key}.json"

        if [[ -f "$action_cache_file" ]]; then
            local cache_timestamp=$(stat -c %Y "$action_cache_file" 2>/dev/null || echo 0)
            time_remaining=$(calculate_current_time_remaining "$period" "$time_remaining" "$cache_timestamp")

            # If expired, get fresh data
            if [[ $time_remaining -le 0 ]]; then
                rm -f "$action_cache_file"
                # ALSO invalidate the underlying account cache to force fresh API calls
                local cache_key
                cache_key=$(echo -n "${account_name}_${issuer}" | md5sum | cut -d' ' -f1)
                local account_cache_file="$TEMP_DIR/account_${cache_key}.json"
                rm -f "$account_cache_file"

                action_data=$(get_cached_action_data "$account_name" "$issuer")
                otp_code=$(echo "$action_data" | jq -r '.otp_code')
                time_remaining=$(echo "$action_data" | jq -r '.time_remaining // "null"')
            fi
        fi
    fi

    local options prompt_text
    if [[ "$type" == "totp" && "$time_remaining" != "null" && "$time_remaining" != "0" ]]; then
        # Calculate time-based info for better user experience
        local time_info=""
        if [[ $time_remaining -le 5 ]]; then
            time_info=" ⚠️ EXPIRES IN ${time_remaining}s!"
            prompt_text="$account_name ($issuer)${time_info}"
        elif [[ $time_remaining -le 15 ]]; then
            time_info=" ⏰ ${time_remaining}s left"
            prompt_text="$account_name ($issuer)${time_info}"
        else
            prompt_text="$account_name ($issuer) - Choose action:"
        fi

        options="🎯 Copy OTP ($otp_code)
⏰ Valid for $time_remaining more seconds
🔐 Copy Secret
✏️  Edit account
🗑️  Delete account
❌ Back"
    elif [[ "$type" == "hotp" ]]; then
        prompt_text="$account_name ($issuer) - Choose action:"
        options="🎯 Copy OTP ($otp_code)
🔄 Increment counter
🔐 Copy Secret
✏️  Edit account
🗑️  Delete account
❌ Back"
    else
        prompt_text="$account_name ($issuer) - Choose action:"
        options="🎯 Copy OTP ($otp_code)
🔐 Copy Secret
✏️  Edit account
🗑️  Delete account
❌ Back"
    fi

    echo "$options" | rofi -dmenu -i -p "$prompt_text" -theme-str 'window {width: 450px;}'
}

# Function to handle account actions
handle_account_action() {
    local account_name="$1"
    local issuer="$2"
    local action="$3"

    case "$action" in
        *"Copy OTP"*)
            local otp_code
            otp_code=$("$NCOTP_CLI" generate "$account_name" "$issuer" 2>/dev/null)

            if [[ -n "$otp_code" && "$otp_code" != "Error" ]]; then
                copy_to_clipboard "$otp_code" "OTP code for $account_name ($issuer)"
            else
                rofi -e "Failed to generate OTP code for $account_name ($issuer)"
            fi
            ;;
        *"Copy Secret")
            # Get the decrypted secret from cached action data
            local action_data
            action_data=$(get_cached_action_data "$account_name" "$issuer")
            local decrypted_secret=$(echo "$action_data" | jq -r '.decrypted_secret')

            if [[ -n "$decrypted_secret" && "$decrypted_secret" != "null" ]]; then
                copy_to_clipboard "$decrypted_secret" "Secret for $account_name ($issuer)"
            else
                rofi -e "Failed to retrieve secret for $account_name ($issuer)"
            fi
            ;;
        *"Increment counter")
            local result
            result=$("$NCOTP_CLI" hotp-step "$account_name" "$issuer" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                rofi -e "HOTP counter incremented for $account_name ($issuer)"
                # Invalidate cache to get updated counter
                invalidate_account_cache "$account_name" "$issuer"
            else
                rofi -e "Failed to increment HOTP counter"
            fi
            ;;
        "✏️  Edit account")
            edit_existing_account "$account_name" "$issuer" || true
            ;;
        "🗑️  Delete account")
            local confirm
            confirm=$(echo -e "No\nYes" | rofi -dmenu -p "Delete account '$account_name ($issuer)'?")
            if [[ "$confirm" == "Yes" ]]; then
                local delete_result
                delete_result=$("$NCOTP_CLI" delete "$account_name" "$issuer" 2>&1 <<< "y")

                if [[ $? -eq 0 ]]; then
                    invalidate_account_cache "$account_name" "$issuer"
                    rofi -e "Account '$account_name ($issuer)' deleted successfully"
                else
                    rofi -e "Failed to delete account: $delete_result"
                fi
            fi
            ;;
    esac
}

# Function to save form state
save_form_state() {
    local name="$1" issuer="$2" secret="$3" type="$4" digits="$5" period="$6" algorithm="$7" secret_changed="${8:-false}"
    cat > "$FORM_STATE_FILE" << EOF
name=$(printf '%q' "$name")
issuer=$(printf '%q' "$issuer")
secret=$(printf '%q' "$secret")
type=$(printf '%q' "$type")
digits=$digits
period=$period
algorithm=$algorithm
secret_changed=$secret_changed
EOF
}

# Function to load form state
load_form_state() {
    if [[ -f "$FORM_STATE_FILE" ]]; then
        source "$FORM_STATE_FILE"
    else
        name=""
        issuer=""
        secret=""
        type="totp"
        digits=6
        period=30
        algorithm=0
        secret_changed=false
    fi
}

# Function to clear form state
clear_form_state() {
    rm -f "$FORM_STATE_FILE"
}

# Function to save session state (what screen we're on)
save_session_state() {
    local screen="$1"
    local selected_name="$2"
    local selected_issuer="$3"
    cat > "$SESSION_STATE_FILE" << EOF
current_screen='$screen'
selected_account_name='$selected_name'
selected_account_issuer='$selected_issuer'
EOF
}

# Function to load session state
load_session_state() {
    if [[ -f "$SESSION_STATE_FILE" ]]; then
        source "$SESSION_STATE_FILE"
    else
        current_screen="main"
        selected_account_name=""
        selected_account_issuer=""
    fi
}

# Function to clear session state
clear_session_state() {
    rm -f "$SESSION_STATE_FILE"
}

# Function to show editable form for account
show_account_form() {
    local mode="$1"  # "create" or "edit"
    local existing_name="$2"
    local existing_issuer="$3"

    # Get existing values if editing
    local current_name current_issuer current_type current_digits current_period current_algorithm
    if [[ "$mode" == "edit" ]]; then
        local account_data
        account_data=$(get_cached_account_data "$existing_name" "$existing_issuer")
        current_name=$(echo "$account_data" | jq -r '.name // ""' 2>/dev/null || echo "")
        current_issuer=$(echo "$account_data" | jq -r '.issuer // ""' 2>/dev/null || echo "")
        current_type=$(echo "$account_data" | jq -r '.type // "totp"' 2>/dev/null || echo "totp")
        current_digits=$(echo "$account_data" | jq -r '.digits // 6' 2>/dev/null || echo "6")
        current_period=$(echo "$account_data" | jq -r '.period // 30' 2>/dev/null || echo "30")
        current_algorithm=$(echo "$account_data" | jq -r '.algorithm // 0' 2>/dev/null || echo "0")
    fi

    # Load persistent state or initialize form values
    if [[ "$mode" == "create" ]]; then
        load_form_state
    else
        # For edit mode, start with actual account values
        name="${current_name:-}"
        issuer="${current_issuer:-}"
        secret=""
        type="${current_type:-totp}"
        digits="${current_digits:-6}"
        period="${current_period:-30}"
        algorithm="${current_algorithm:-0}"
        secret_changed=false

        # Only override with saved state if it's for the same account
        if [[ -f "$FORM_STATE_FILE" ]]; then
            load_form_state
            # Only use saved state if it matches the same account we're editing
            if [[ "$name" != "$current_name" || "$issuer" != "$current_issuer" ]]; then
                # Different account - ignore saved state and use account values
                name="${current_name:-}"
                issuer="${current_issuer:-}"
                secret=""
                type="${current_type:-totp}"
                digits="${current_digits:-6}"
                period="${current_period:-30}"
                algorithm="${current_algorithm:-0}"
                secret_changed=false
            fi
        fi
    fi

    while true; do
        local algorithm_name="SHA1"
        case "$algorithm" in
            1) algorithm_name="SHA256" ;;
            2) algorithm_name="SHA512" ;;
        esac

        local form_display
        if [[ "$mode" == "edit" ]]; then
            form_display="📝 Name: ${name} (read-only)
🏢 Issuer: ${issuer} (read-only)
🔢 Type: ${type^^} ▼
🎯 Digits: ${digits}
⏱️ Period: ${period} seconds
🖥️ Algorithm: ${algorithm_name} ▼
────────────────────────────
💾 Save account
❌ Back"
        else
            form_display="📝 Name: ${name:-"(required)"}
🏢 Issuer: ${issuer:-"(required)"}
🔐 Secret: ${secret:-"(required)"}
🔢 Type: ${type^^} ▼
🎯 Digits: ${digits}
⏱️ Period: ${period} seconds
🖥️ Algorithm: ${algorithm_name} ▼
────────────────────────────
💾 Save account
❌ Back"
        fi

        local choice
        choice=$(echo -e "$form_display" | rofi -dmenu -i -p "${mode^} OTP Account:" -theme-str 'window {width: 500px;}')

        case "$choice" in
            *"Name:"*)
                if [[ "$mode" == "create" ]]; then
                    local new_name
                    new_name=$(rofi -dmenu -p "Enter account name:" -filter "$name" -theme-str 'window {width: 400px;}')
                    if [[ -n "$new_name" ]]; then
                        name="$new_name"
                    fi
                    save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                else
                    rofi -e "Name cannot be changed (it's the primary key)"
                fi
                ;;
            *"Issuer:"*)
                if [[ "$mode" == "create" ]]; then
                    local new_issuer
                    new_issuer=$(rofi -dmenu -p "Enter issuer/service name:" -filter "$issuer" -theme-str 'window {width: 400px;}')
                    if [[ -n "$new_issuer" ]]; then
                        issuer="$new_issuer"
                    fi
                    save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                else
                    rofi -e "Issuer cannot be changed (it's the primary key)"
                fi
                ;;
            *"Secret:"*)
                # Secret editing only available in create mode
                if [[ "$mode" == "create" ]]; then
                    local new_secret
                    new_secret=$(rofi -dmenu -password -p "Enter Base32 secret:" -theme-str 'window {width: 400px;}')
                    if [[ -n "$new_secret" ]]; then
                        secret="$new_secret"
                        secret_changed=true
                    fi
                    save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                fi
                ;;
            *"Type:"*)
                local type_options="TOTP\nHOTP"
                local new_type
                new_type=$(echo -e "$type_options" | rofi -dmenu -p "Select OTP type:")
                if [[ -n "$new_type" ]]; then
                    type=$(echo "$new_type" | tr '[:upper:]' '[:lower:]')
                fi
                save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                ;;
            *"Digits:"*)
                local digits_options="4\n6"
                local new_digits
                new_digits=$(echo -e "$digits_options" | rofi -dmenu -p "Select number of digits:")
                if [[ -n "$new_digits" ]]; then
                    digits="$new_digits"
                fi
                save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                ;;
            *"Period:"*)
                local new_period
                new_period=$(rofi -dmenu -p "Enter period in seconds:" -filter "$period" -theme-str 'window {width: 400px;}')
                if [[ -n "$new_period" && "$new_period" =~ ^[0-9]+$ ]]; then
                    period="$new_period"
                fi
                save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                ;;
            *"Algorithm:"*)
                local algo_options="SHA1\nSHA256\nSHA512"
                local new_algo
                new_algo=$(echo -e "$algo_options" | rofi -dmenu -p "Select hash algorithm:")
                case "$new_algo" in
                    "SHA1") algorithm=0 ;;
                    "SHA256") algorithm=1 ;;
                    "SHA512") algorithm=2 ;;
                esac
                save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                ;;
            *"Save account")
                # Validate required fields
                if [[ -z "$name" ]]; then
                    rofi -e "Name is required!"
                    continue
                fi
                if [[ -z "$issuer" ]]; then
                    rofi -e "Issuer is required!"
                    continue
                fi
                if [[ "$mode" == "create" && -z "$secret" ]]; then
                    rofi -e "Secret is required for new accounts!"
                    continue
                fi

                # Execute save
                if save_account "$mode" "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"; then
                    clear_form_state
                    # Invalidate cache after successful save
                    invalidate_account_cache "$name" "$issuer"
                    if [[ "$mode" == "edit" ]]; then
                        # For edit, save session to return to action menu on next startup
                        save_session_state "action_menu" "$name" "$issuer"
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
                    save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                    save_session_state "edit_form" "$name" "$issuer"
                    exit 0
                else
                    # For create, save current form state and set session to resume creating
                    save_form_state "$name" "$issuer" "$secret" "$type" "$digits" "$period" "$algorithm" "$secret_changed"
                    save_session_state "create_form" "" ""
                    exit 0
                fi
                ;;
        esac
    done
}

# Function to save account
save_account() {
    local mode="$1"
    local name="$2"
    local issuer="$3"
    local secret="$4"
    local type="$5"
    local digits="$6"
    local period="$7"
    local algorithm="$8"
    local secret_changed="${9:-false}"

    local cmd result

    if [[ "$mode" == "create" ]]; then
        # Create new account
        cmd=("$NCOTP_CLI" "create" "$name" "--secret" "$secret" "--issuer" "$issuer" "--type" "$type" "--digits" "$digits" "--period" "$period" "--algorithm" "$algorithm")
    else
        # Update existing account (no secret changes allowed)
        cmd=("$NCOTP_CLI" "update" "$name" "$issuer" "--type" "$type" "--digits" "$digits" "--period" "$period" "--algorithm" "$algorithm")
    fi

    result=$("${cmd[@]}" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        rofi -e "Account '${name} (${issuer})' ${mode}d successfully!"
        return 0
    else
        rofi -e "Failed to ${mode} account: $result"
        return 1
    fi
}

# Function to create new OTP account
create_new_account() {
    save_session_state "create_form" "" ""
    if show_account_form "create"; then
        # Form was saved successfully
        clear_session_state
    else
        # Form was cancelled with back button - keep session state for persistence
        :
    fi
}

# Function to edit existing account
edit_existing_account() {
    local account_name="$1"
    local issuer="$2"

    save_session_state "edit_form" "$account_name" "$issuer"
    if show_account_form "edit" "$account_name" "$issuer"; then
        # Form was saved successfully - return to action menu
        save_session_state "action_menu" "$account_name" "$issuer"
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
        create_new_account
        # Don't return - let it fall through to normal main loop
    elif [[ "$current_screen" == "action_menu" ]] && [[ -n "$selected_account_name" ]] && [[ -n "$selected_account_issuer" ]]; then
        # Resume the action menu for the selected account
        show_action_menu_loop "$selected_account_name" "$selected_account_issuer"
        # Don't return - let it fall through to normal main loop
    elif [[ "$current_screen" == "edit_form" ]] && [[ -n "$selected_account_name" ]] && [[ -n "$selected_account_issuer" ]]; then
        # Resume editing - preserve form state and call form directly
        if show_account_form "edit" "$selected_account_name" "$selected_account_issuer"; then
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

        if [[ "$selected_account" == "🆕 Create new OTP account" ]]; then
            create_new_account
            continue
        fi

        if [[ "$selected_account" == "🔄 Refresh account list" ]]; then
            refresh_cache
            continue
        fi

        # Parse selected account to get name/issuer
        if parse_account_selection "$selected_account"; then
            # Start background prefetch of both account and action data
            prefetch_account_data "$selected_account_name" "$selected_account_issuer"
            prefetch_action_data "$selected_account_name" "$selected_account_issuer"

            # Show action menu for selected account
            show_action_menu_loop "$selected_account_name" "$selected_account_issuer"
        else
            rofi -e "Could not parse account selection: $selected_account"
        fi
        # If action menu returns (Back button), continue main loop
    done
}


# Function to handle the action menu loop with persistence and auto-refresh
show_action_menu_loop() {
    local account_name="$1"
    local issuer="$2"
    save_session_state "action_menu" "$account_name" "$issuer"

    while true; do
        local action
        action=$(show_action_menu "$account_name" "$issuer")

        if [[ -z "$action" || "$action" == "❌ Back" ]]; then
            clear_session_state
            break  # Go back to account selection
        fi

        handle_account_action "$account_name" "$issuer" "$action"

        # Handle different actions
        if [[ "$action" == *"Copy OTP"* || "$action" == *"Copy Secret"* || "$action" == *"Increment counter" ]]; then
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