#!/usr/bin/env bash

# ncpass-bash.sh - Pure bash implementation of ncpass CLI
# Replaces Node.js dependency with curl + jq

set -e

VERSION="1.3.0"

# Hardcoded configuration
NEXTCLOUD_URL="https://nc.liam-w.com"
NEXTCLOUD_USER="liam-w"
NEXTCLOUD_TOKEN="REDACTED003"

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

# API endpoints
API_BASE="${NEXTCLOUD_URL}/index.php/apps/passwords/api/1.0"
AUTH_HEADER="Authorization: Basic $(echo -n "${NEXTCLOUD_USER}:${NEXTCLOUD_TOKEN}" | base64)"

# Function to make API requests
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local curl_args=("-s" "-X" "$method" "-H" "$AUTH_HEADER" "-H" "Content-Type: application/json")

    if [[ -n "$data" ]]; then
        curl_args+=("-d" "$data")
    fi

    curl "${curl_args[@]}" "${API_BASE}${endpoint}"
}

# Get all passwords
get_all_passwords() {
    api_request "GET" "/password/list"
}

# Find password by label
find_password_by_label() {
    local label="$1"
    get_all_passwords | jq -r --arg label "$label" '.[] | select(.label == $label)'
}

# Generate random password
generate_password() {
    local length=20
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local password=""

    for ((i=0; i<length; i++)); do
        if [[ $((i % 5)) -eq 0 && i -ne 0 ]]; then
            password+="-"
        fi
        password+="${chars:RANDOM%${#chars}:1}"
    done

    echo "$password"
}

# Parse command line arguments
args=("$@")

# Extract options
declare -A options
filtered_args=()

i=0
while [[ $i -lt ${#args[@]} ]]; do
    if [[ "${args[i]}" =~ ^--(.+)$ ]]; then
        key="${BASH_REMATCH[1]}"
        if [[ $((i+1)) -lt ${#args[@]} ]]; then
            options["$key"]="${args[$((i+1))]}"
            i=$((i+2))
        else
            echo "Error: Option --$key requires a value" >&2
            exit 1
        fi
    else
        filtered_args+=("${args[i]}")
        i=$((i+1))
    fi
done

# Filter out empty arguments
final_args=()
for arg in "${filtered_args[@]}"; do
    if [[ -n "$arg" ]]; then
        final_args+=("$arg")
    fi
done

# Parse command and arguments
command="${final_args[0]}"
label="${final_args[1]}"

case "$command" in
    "list")
        get_all_passwords | jq -r '.[] | .label'
        ;;

    "get"|"getpass")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            echo "$password_data" | jq -r '.password'
        else
            echo "Error: Password not found: $label" >&2
            exit 1
        fi
        ;;

    "getuser")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            echo "$password_data" | jq -r '.username // ""'
        fi
        ;;

    "geturl")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            echo "$password_data" | jq -r '.url // ""'
        fi
        ;;

    "getnotes")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            echo "$password_data" | jq -r '.notes // ""'
        fi
        ;;

    "getall")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            echo "$password_data" | jq '{label: .label, username: .username, password: .password, url: .url, notes: .notes}'
        else
            echo "Error: Password not found: $label" >&2
            exit 1
        fi
        ;;

    "set")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        # Parse arguments: set label [username] [password]
        username="${final_args[2]}"
        password="${final_args[3]}"

        # If only 3 args, then arg[2] is password, not username
        if [[ ${#final_args[@]} -eq 3 ]]; then
            username=""
            password="${final_args[2]}"
        fi

        # Get existing password if it exists
        existing_data=$(find_password_by_label "$label")

        # Build password object
        if [[ -n "$existing_data" ]]; then
            # Update existing
            password_obj=$(echo "$existing_data" | jq --arg username "$username" --arg password "$password" '
                if $username != "" then .username = $username else . end |
                if $password != "" then .password = $password else . end
            ')

            # Add options
            for key in "${!options[@]}"; do
                password_obj=$(echo "$password_obj" | jq --arg key "$key" --arg value "${options[$key]}" '.[$key] = $value')
            done

            # Update password
            password_id=$(echo "$existing_data" | jq -r '.id')
            api_request "PATCH" "/password/update" "$password_obj" > /dev/null
        else
            # Create new
            password_obj=$(jq -n --arg label "$label" --arg username "$username" --arg password "$password" '{
                label: $label,
                username: $username,
                password: $password
            }')

            # Add options
            for key in "${!options[@]}"; do
                password_obj=$(echo "$password_obj" | jq --arg key "$key" --arg value "${options[$key]}" '.[$key] = $value')
            done

            api_request "POST" "/password/create" "$password_obj" > /dev/null
        fi
        ;;

    "generate"|"gen")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        username="${final_args[2]}"
        generated_password=$(generate_password)

        # Get existing password if it exists
        existing_data=$(find_password_by_label "$label")

        if [[ -n "$existing_data" ]]; then
            # Update existing
            password_obj=$(echo "$existing_data" | jq --arg password "$generated_password" '.password = $password')
            if [[ -n "$username" ]]; then
                password_obj=$(echo "$password_obj" | jq --arg username "$username" '.username = $username')
            fi

            # Add options
            for key in "${!options[@]}"; do
                password_obj=$(echo "$password_obj" | jq --arg key "$key" --arg value "${options[$key]}" '.[$key] = $value')
            done

            password_id=$(echo "$existing_data" | jq -r '.id')
            api_request "PATCH" "/password/update" "$password_obj" > /dev/null
        else
            # Create new
            password_obj=$(jq -n --arg label "$label" --arg username "$username" --arg password "$generated_password" '{
                label: $label,
                username: $username,
                password: $password
            }')

            # Add options
            for key in "${!options[@]}"; do
                password_obj=$(echo "$password_obj" | jq --arg key "$key" --arg value "${options[$key]}" '.[$key] = $value')
            done

            api_request "POST" "/password/create" "$password_obj" > /dev/null
        fi

        echo "$generated_password"
        ;;

    "delete"|"del")
        if [[ -z "$label" ]]; then
            echo "Error: missing arguments! at least label is required" >&2
            exit 1
        fi

        password_data=$(find_password_by_label "$label")
        if [[ -n "$password_data" ]]; then
            password_id=$(echo "$password_data" | jq -r '.id')
            api_request "DELETE" "/password/delete" "$password_data" > /dev/null
            echo "Deleted: $label" >&2
        else
            echo "Error: Password not found: $label" >&2
            exit 1
        fi
        ;;

    "-h"|"--help")
        echo "NCPass v$VERSION"
        echo ""
        echo "Usage: ncpass <command> <label> <user> <password> [options]"
        echo ""
        echo "Commands: set, get, getuser, geturl, getnotes, generate, delete, list, getall"
        echo "Options: --url <url>, --notes <notes>"
        echo ""
        echo "Examples:"
        echo "  ncpass generate my_pass_name"
        echo "  ncpass generate my_pass_name username --url my_url"
        echo "  ncpass get my_pass_name"
        echo "  ncpass set my_pass_name password"
        echo "  ncpass set my_pass_name username password"
        ;;

    *)
        echo "NCPass v$VERSION"
        echo ""
        echo "Usage: ncpass <command> <label> <user> <password> [options]"
        echo ""
        echo "Commands: set, get, getuser, geturl, getnotes, generate, delete, list, getall"
        echo "Options: --url <url>, --notes <notes>"
        ;;
esac
