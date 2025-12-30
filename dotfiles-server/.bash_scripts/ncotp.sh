#!/usr/bin/env bash

# ncotp.sh - Pure bash implementation of Nextcloud OTP Manager CLI
# API abstraction layer for Nextcloud OTP Manager app

set -e
set +H  # Disable history expansion

# Cleanup trap handlers will be set after session functions are defined

# Hardcoded configuration
NEXTCLOUD_URL="https://nc.liam-w.com"
NEXTCLOUD_USER="liam-w"
NEXTCLOUD_TOKEN="REDACTED003"
OTP_MASTER_PASSWORD='REDACTED001'

# Check dependencies
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed." >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is required but not installed." >&2
    exit 1
fi

if ! command -v oathtool &> /dev/null; then
    echo "Error: oathtool is required but not installed." >&2
    exit 1
fi

# API configuration
USER_AGENT="Simple OTP Manager CLI"
OCS_API_REQUEST="true"
AUTH_HEADER="Authorization: Basic $(echo -n "${NEXTCLOUD_USER}:${NEXTCLOUD_TOKEN}" | base64)"

# Cache for IV to avoid multiple password checks
CACHED_IV=""

# Session management for CSRF-protected operations
SESSION_COOKIE_FILE="/tmp/ncotp_session_$$"
CACHED_CSRF_TOKEN=""

# Initialize session for CSRF-protected operations
init_session() {
    # Establish session by accessing main page
    curl -s -c "$SESSION_COOKIE_FILE" \
         -H "User-Agent: $USER_AGENT" \
         -H "$AUTH_HEADER" \
         "${NEXTCLOUD_URL}/" > /dev/null

    # Get fresh CSRF token
    CACHED_CSRF_TOKEN=$(curl -s -b "$SESSION_COOKIE_FILE" \
                             -H "User-Agent: $USER_AGENT" \
                             -H "$AUTH_HEADER" \
                             "${NEXTCLOUD_URL}/index.php/csrftoken" | jq -r .token)

    if [[ -z "$CACHED_CSRF_TOKEN" || "$CACHED_CSRF_TOKEN" == "null" ]]; then
        echo "Error: Failed to get CSRF token" >&2
        return 1
    fi
}

# Get current CSRF token (initialize session if needed)
get_csrf_token() {
    if [[ -z "$CACHED_CSRF_TOKEN" ]] || [[ ! -f "$SESSION_COOKIE_FILE" ]]; then
        init_session || return 1
    fi
    echo "$CACHED_CSRF_TOKEN"
}

# Cleanup session files
cleanup_session() {
    [[ -f "$SESSION_COOKIE_FILE" ]] && rm -f "$SESSION_COOKIE_FILE"
    CACHED_CSRF_TOKEN=""
}

# Setup cleanup trap handlers now that cleanup_session is defined
cleanup_on_exit() {
    cleanup_session
}

cleanup_on_error() {
    cleanup_session
    exit 1
}

# Set traps for automatic cleanup
trap cleanup_on_exit EXIT
trap cleanup_on_error ERR INT TERM

# Function to make API requests (read-only, no CSRF needed)
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local content_type="${4:-application/json}"

    local curl_args=("-s" "-w" "%{http_code}" "-X" "$method")
    curl_args+=("-H" "User-Agent: $USER_AGENT")
    curl_args+=("-H" "OCS-APIRequest: $OCS_API_REQUEST")
    curl_args+=("-H" "$AUTH_HEADER")
    curl_args+=("-H" "Content-Type: $content_type")

    if [[ -n "$data" ]]; then
        curl_args+=("-d" "$data")
    fi

    curl "${curl_args[@]}" "${NEXTCLOUD_URL}${endpoint}"
}

# Function to make CSRF-protected API requests (for CRUD operations)
csrf_request() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local content_type="${4:-application/json}"

    # Get CSRF token (initializes session if needed)
    local csrf_token
    csrf_token=$(get_csrf_token) || return 1

    local curl_args=("-s" "-w" "%{http_code}" "-X" "$method")
    curl_args+=("-b" "$SESSION_COOKIE_FILE" "-c" "$SESSION_COOKIE_FILE")
    curl_args+=("-H" "User-Agent: $USER_AGENT")
    curl_args+=("-H" "OCS-APIRequest: $OCS_API_REQUEST")
    curl_args+=("-H" "$AUTH_HEADER")
    curl_args+=("-H" "Content-Type: $content_type")
    curl_args+=("-H" "requesttoken: $csrf_token")
    curl_args+=("-H" "X-Requested-With: XMLHttpRequest")

    if [[ -n "$data" ]]; then
        curl_args+=("-d" "$data")
    fi

    curl "${curl_args[@]}" "${NEXTCLOUD_URL}${endpoint}"
}

# Check master password and get IV
check_master_password() {
    local password="$1"

    if [[ -z "$password" ]]; then
        password="$OTP_MASTER_PASSWORD"
    fi

    local response=$(api_request "POST" "/ocs/v2.php/apps/otpmanager/password/check" "{\"password\":\"$password\"}")
    local http_code="${response: -3}"
    local body="${response%???}"

    case "$http_code" in
        200)
            local iv=$(echo "$body" | jq -r '.iv // empty')
            if [[ -n "$iv" && "$iv" != "null" ]]; then
                CACHED_IV="$iv"
                return 0
            else
                echo "Error: Invalid response format" >&2
                return 1
            fi
            ;;
        400)
            echo "Error: Invalid master password" >&2
            return 1
            ;;
        401)
            echo "Error: Authentication failed - check app token" >&2
            return 1
            ;;
        404)
            echo "Error: OTP Manager app not found - check installation" >&2
            return 1
            ;;
        *)
            echo "Error: HTTP $http_code" >&2
            return 1
            ;;
    esac
}

# Get encryption IV (calls check_master_password if not cached)
get_encryption_iv() {
    if [[ -z "$CACHED_IV" ]]; then
        check_master_password "$OTP_MASTER_PASSWORD" || return 1
    fi
    echo "$CACHED_IV"
}

# Hash master password for decryption
hash_master_password() {
    local password="$1"
    echo -n "$password" | openssl dgst -sha256 -hex | sed 's/^.* //'
}

# AES decrypt account secret (matching CryptoJS implementation)
aes_decrypt() {
    local encrypted_secret="$1"
    local key="$2"
    local iv="$3"

    # Use the exact working approach from our test
    local result=$(echo "$encrypted_secret" | base64 -d | openssl enc -aes-256-cbc -d -K "$key" -iv "$iv" -nopad 2>/dev/null)

    if [[ -n "$result" ]]; then
        echo "$result"
        return 0
    fi

    # Fallback: try with base64 input directly
    result=$(echo -n "$encrypted_secret" | openssl enc -aes-256-cbc -d -base64 -K "$key" -iv "$iv" -nopad 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo "$result"
        return 0
    fi

    # Second fallback: try standard padding
    result=$(echo -n "$encrypted_secret" | openssl enc -aes-256-cbc -d -base64 -K "$key" -iv "$iv" 2>/dev/null)
    if [[ -n "$result" ]]; then
        echo "$result"
        return 0
    fi

    # If all approaches fail, return empty
    return 1
}

# Get all OTP accounts
list_accounts() {
    local response=$(api_request "GET" "/index.php/apps/otpmanager/accounts")
    local http_code="${response: -3}"
    local body="${response%???}"

    case "$http_code" in
        200)
            echo "$body" | jq -r '.accounts + (.shared_accounts // [])'
            ;;
        401)
            echo "Error: Authentication failed" >&2
            return 1
            ;;
        404)
            echo "Error: OTP Manager not found" >&2
            return 1
            ;;
        *)
            echo "Error: HTTP $http_code" >&2
            return 1
            ;;
    esac
}

# Find account by name and optionally issuer
find_account() {
    local account_name="$1"
    local issuer="$2"

    local accounts=$(list_accounts) || return 1

    if [[ -n "$issuer" ]]; then
        echo "$accounts" | jq -r --arg name "$account_name" --arg issuer "$issuer" \
            '.[] | select(.name == $name and .issuer == $issuer)'
    else
        # Find by name only, return first match
        echo "$accounts" | jq -r --arg name "$account_name" \
            '[.[] | select(.name == $name)] | .[0] // empty'
    fi
}

# Get account details
get_account() {
    local account_name="$1"
    local issuer="$2"

    local account=$(find_account "$account_name" "$issuer")

    if [[ -z "$account" || "$account" == "null" ]]; then
        echo "Error: Account not found: $account_name${issuer:+ ($issuer)}" >&2
        return 1
    fi

    echo "$account"
}

# Get time remaining for TOTP
get_time_remaining() {
    local period="$1"
    local current_time=$(date +%s)
    echo $(( period - (current_time % period) ))
}

# Generate TOTP
generate_totp() {
    local account_name="$1"
    local issuer="$2"

    # Get IV
    local iv=$(get_encryption_iv) || return 1

    # Find account
    local account=$(get_account "$account_name" "$issuer") || return 1

    # Extract account details
    local encrypted_secret=$(echo "$account" | jq -r '.secret')
    local algorithm=$(echo "$account" | jq -r '.algorithm')
    local digits=$(echo "$account" | jq -r '.digits')
    local period=$(echo "$account" | jq -r '.period // 30')

    # Generate password hash for decryption
    local password_hash=$(hash_master_password "$OTP_MASTER_PASSWORD")


    # Decrypt secret
    local decrypted_secret=$(aes_decrypt "$encrypted_secret" "$password_hash" "$iv")

    if [[ -z "$decrypted_secret" ]]; then
        echo "Error: Failed to decrypt secret" >&2
        return 1
    fi

    # Clean up the decrypted secret - extract only the meaningful part (first 16 chars)
    # The secret is padded with spaces to 32 chars, we only need the first part
    decrypted_secret=$(echo -n "$decrypted_secret" | head -c 16)

    # Generate TOTP
    local hash_algo="SHA1"
    case "$algorithm" in
        1) hash_algo="SHA256" ;;
        2) hash_algo="SHA512" ;;
    esac

    oathtool --base32 --totp="$hash_algo" --digits="$digits" --time-step-size="${period}s" \
        "$decrypted_secret"
}

# Generate HOTP
generate_hotp() {
    local account_name="$1"
    local issuer="$2"

    # Get IV
    local iv=$(get_encryption_iv) || return 1

    # Find account
    local account=$(get_account "$account_name" "$issuer") || return 1

    # Extract account details
    local encrypted_secret=$(echo "$account" | jq -r '.secret')
    local algorithm=$(echo "$account" | jq -r '.algorithm')
    local digits=$(echo "$account" | jq -r '.digits')
    local counter=$(echo "$account" | jq -r '.counter')

    # Generate password hash for decryption
    local password_hash=$(hash_master_password "$OTP_MASTER_PASSWORD")

    # Decrypt secret
    local decrypted_secret=$(aes_decrypt "$encrypted_secret" "$password_hash" "$iv")

    if [[ -z "$decrypted_secret" ]]; then
        echo "Error: Failed to decrypt secret" >&2
        return 1
    fi

    # Clean up the decrypted secret - extract only the meaningful part
    decrypted_secret=$(echo -n "$decrypted_secret" | head -c 16)

    # Generate HOTP
    local hash_algo="SHA1"
    case "$algorithm" in
        1) hash_algo="SHA256" ;;
        2) hash_algo="SHA512" ;;
    esac

    local otp_code=$(oathtool --base32 --hotp --counter="$counter" --digits="$digits" \
        "$decrypted_secret")

    # Update counter on server
    increment_hotp_counter "$account_name" "$issuer"

    echo "$otp_code"
}

# Increment HOTP counter on server
increment_hotp_counter() {
    local account_name="$1"
    local issuer="$2"

    # Get account to find encrypted secret
    local account=$(get_account "$account_name" "$issuer") || return 1
    local encrypted_secret=$(echo "$account" | jq -r '.secret')

    # URL encode the secret
    local encoded_secret=$(printf '%s' "$encrypted_secret" | jq -sRr @uri)

    local response=$(api_request "POST" "/ocs/v2.php/apps/otpmanager/accounts/update-counter" \
        "secret=${encoded_secret}" "application/x-www-form-urlencoded")

    local http_code="${response: -3}"

    if [[ "$http_code" != "200" ]]; then
        echo "Warning: Failed to update HOTP counter on server (HTTP $http_code)" >&2
    fi
}

# Create a new OTP account
create_account() {
    local name="$1"
    local secret="$2"
    local issuer="${3:-}"
    local type="${4:-totp}"
    local digits="${5:-6}"
    local period="${6:-30}"
    local algorithm="${7:-0}"  # 0=SHA1, 1=SHA256, 2=SHA512

    # Validate required parameters
    if [[ -z "$name" || -z "$secret" ]]; then
        echo "Error: Name and secret are required" >&2
        return 1
    fi

    # Get IV for encryption
    local iv
    iv=$(get_encryption_iv) || return 1

    # Generate password hash for encryption
    local password_hash
    password_hash=$(hash_master_password "$OTP_MASTER_PASSWORD")

    # Encrypt the secret using same method as web interface
    local encrypted_secret
    encrypted_secret=$(echo -n "$secret" | openssl enc -aes-256-cbc -e -base64 -K "$password_hash" -iv "$iv")

    if [[ -z "$encrypted_secret" ]]; then
        echo "Error: Failed to encrypt secret" >&2
        return 1
    fi

    # Prepare account data as form data (controller may expect this format)
    local account_data="data[name]=$(printf '%s' "$name" | jq -sRr @uri)"
    account_data="${account_data}&data[issuer]=$(printf '%s' "$issuer" | jq -sRr @uri)"
    account_data="${account_data}&data[secret]=$(printf '%s' "$encrypted_secret" | jq -sRr @uri)"
    account_data="${account_data}&data[type]=$(printf '%s' "$type" | jq -sRr @uri)"
    account_data="${account_data}&data[digits]=$digits"
    account_data="${account_data}&data[period]=$period"
    account_data="${account_data}&data[algorithm]=$algorithm"
    account_data="${account_data}&data[counter]=0"

    # Make CSRF-protected request
    local response
    response=$(csrf_request "POST" "/index.php/apps/otpmanager/accounts" "$account_data" "application/x-www-form-urlencoded")
    local http_code="${response: -3}"
    local body="${response%???}"

    case "$http_code" in
        200|201)
            echo "Account created successfully"
            return 0
            ;;
        400)
            echo "Error: Invalid account data" >&2
            echo "$body" >&2
            return 1
            ;;
        409)
            echo "Error: Account already exists" >&2
            return 1
            ;;
        *)
            echo "Error: HTTP $http_code" >&2
            echo "$body" >&2
            return 1
            ;;
    esac
}

# Update an existing OTP account
update_account() {
    local name="$1"
    local issuer="$2"
    local new_name="${3:-$name}"
    local new_issuer="${4:-$issuer}"
    local new_type="${5:-}"
    local new_digits="${6:-}"
    local new_period="${7:-}"
    local new_algorithm="${8:-}"

    # Get existing account first
    local account
    account=$(get_account "$name" "$issuer") || return 1

    # Extract current values if not provided
    if [[ -z "$new_type" ]]; then
        new_type=$(echo "$account" | jq -r '.type')
    fi
    if [[ -z "$new_digits" ]]; then
        new_digits=$(echo "$account" | jq -r '.digits')
    fi
    if [[ -z "$new_period" ]]; then
        new_period=$(echo "$account" | jq -r '.period // 30')
    fi
    if [[ -z "$new_algorithm" ]]; then
        new_algorithm=$(echo "$account" | jq -r '.algorithm')
    fi

    local account_id=$(echo "$account" | jq -r '.id')
    local secret=$(echo "$account" | jq -r '.secret')
    local type=$(echo "$account" | jq -r '.type')
    local counter=$(echo "$account" | jq -r '.counter // 0')

    # Prepare updated account data as form data (no secret changes allowed)
    local account_data="data[id]=$account_id"
    account_data="${account_data}&data[name]=$(printf '%s' "$new_name" | jq -sRr @uri)"
    account_data="${account_data}&data[issuer]=$(printf '%s' "$new_issuer" | jq -sRr @uri)"
    account_data="${account_data}&data[secret]=$(printf '%s' "$secret" | jq -sRr @uri)"
    account_data="${account_data}&data[type]=$(printf '%s' "$new_type" | jq -sRr @uri)"
    account_data="${account_data}&data[digits]=$new_digits"
    account_data="${account_data}&data[period]=$new_period"
    account_data="${account_data}&data[algorithm]=$new_algorithm"
    account_data="${account_data}&data[counter]=$counter"

    # Make CSRF-protected request
    local response
    response=$(csrf_request "PUT" "/index.php/apps/otpmanager/accounts" "$account_data" "application/x-www-form-urlencoded")
    local http_code="${response: -3}"
    local body="${response%???}"

    case "$http_code" in
        200)
            # Check if the response indicates validation errors
            if [[ "$body" == '"OK"' ]]; then
                echo "Account updated successfully"
                return 0
            else
                echo "Error: Validation failed" >&2
                # Parse and display validation errors
                echo "$body" | jq -r 'if type == "object" then to_entries[] | "\(.key): \(.value)" else . end' >&2
                return 1
            fi
            ;;
        400)
            echo "Error: Invalid account data" >&2
            echo "$body" >&2
            return 1
            ;;
        404)
            echo "Error: Account not found" >&2
            return 1
            ;;
        412)
            echo "Error: CSRF check failed" >&2
            return 1
            ;;
        *)
            echo "Error: HTTP $http_code" >&2
            echo "$body" >&2
            return 1
            ;;
    esac
}

# Delete an OTP account
delete_account() {
    local name="$1"
    local issuer="$2"

    # Get account to find its ID
    local account
    account=$(get_account "$name" "$issuer") || return 1
    local account_id=$(echo "$account" | jq -r '.id')

    if [[ -z "$account_id" || "$account_id" == "null" ]]; then
        echo "Error: Could not determine account ID" >&2
        return 1
    fi

    # Make CSRF-protected DELETE request
    local response
    response=$(csrf_request "DELETE" "/index.php/apps/otpmanager/accounts/$account_id")
    local http_code="${response: -3}"
    local body="${response%???}"

    case "$http_code" in
        200|204)
            echo "Account deleted successfully"
            return 0
            ;;
        404)
            echo "Error: Account not found" >&2
            return 1
            ;;
        *)
            echo "Error: HTTP $http_code" >&2
            echo "$body" >&2
            return 1
            ;;
    esac
}

# Parse command line arguments (similar to ncpass.sh pattern)
args=("$@")

# Extract options
declare -A options
filtered_args=()

i=0
while [[ $i -lt ${#args[@]} ]]; do
    if [[ "${args[i]}" =~ ^--(.+)$ ]]; then
        key="${BASH_REMATCH[1]}"
        # Special handling for help flag
        if [[ "$key" == "help" ]]; then
            filtered_args+=("${args[i]}")
            i=$((i+1))
        elif [[ $((i+1)) -lt ${#args[@]} ]]; then
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
account_name="${final_args[1]}"
issuer="${final_args[2]}"

case "$command" in
    "list")
        # Default: JSON output for easy parsing
        if [[ "${options["format"]}" == "table" ]]; then
            # Legacy tab-separated format
            list_accounts | jq -r '.[] | "\(.name)\t\(.issuer)\t\(.type)"'
        else
            # JSON format (default) - better for parsing
            list_accounts | jq -r '.[] | {name: .name, issuer: .issuer, type: .type, digits: .digits, algorithm: .algorithm}'
        fi
        ;;

    "generate")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi

        # Get account to determine type
        account=$(get_account "$account_name" "$issuer") || exit 1
        account_type=$(echo "$account" | jq -r '.type')

        case "$account_type" in
            "totp")
                generate_totp "$account_name" "$issuer"
                ;;
            "hotp")
                generate_hotp "$account_name" "$issuer"
                ;;
            *)
                echo "Error: Unknown account type: $account_type" >&2
                exit 1
                ;;
        esac
        ;;

    "get")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi

        get_account "$account_name" "$issuer" | jq '.'
        ;;

    "time")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi

        account=$(get_account "$account_name" "$issuer") || exit 1
        account_type=$(echo "$account" | jq -r '.type')

        if [[ "$account_type" != "totp" ]]; then
            echo "Error: Time remaining only available for TOTP accounts" >&2
            exit 1
        fi

        period=$(echo "$account" | jq -r '.period // 30')
        get_time_remaining "$period"
        ;;

    "hotp-step")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi

        account=$(get_account "$account_name" "$issuer") || exit 1
        account_type=$(echo "$account" | jq -r '.type')

        if [[ "$account_type" != "hotp" ]]; then
            echo "Error: Counter increment only available for HOTP accounts" >&2
            exit 1
        fi

        increment_hotp_counter "$account_name" "$issuer"
        echo "HOTP counter incremented"
        ;;

    "action-data")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi

        # Get account details
        account=$(get_account "$account_name" "$issuer") || exit 1
        account_type=$(echo "$account" | jq -r '.type')

        # Generate OTP code
        case "$account_type" in
            "totp")
                otp_code=$(generate_totp "$account_name" "$issuer" 2>/dev/null || echo "Error")
                # Get time remaining if TOTP
                if [[ "$otp_code" != "Error" ]]; then
                    period=$(echo "$account" | jq -r '.period // 30')
                    time_remaining=$(get_time_remaining "$period")
                else
                    time_remaining=0
                fi
                ;;
            "hotp")
                otp_code=$(generate_hotp "$account_name" "$issuer" 2>/dev/null || echo "Error")
                time_remaining=null
                ;;
            *)
                otp_code="Error"
                time_remaining=null
                ;;
        esac

        # Get decrypted secret for copying (same secret used for OTP generation)
        iv=$(get_encryption_iv) || exit 1
        password_hash=$(hash_master_password "$OTP_MASTER_PASSWORD")
        encrypted_secret=$(echo "$account" | jq -r '.secret')
        decrypted_secret=$(aes_decrypt "$encrypted_secret" "$password_hash" "$iv")

        # Clean up the decrypted secret - extract only the meaningful part
        decrypted_secret=$(echo -n "$decrypted_secret" | head -c 16)

        # Return unified JSON response
        echo "$account" | jq --arg otp "$otp_code" --argjson time_remaining "$time_remaining" --arg secret "$decrypted_secret" \
            '. + {otp_code: $otp, time_remaining: $time_remaining, decrypted_secret: $secret}'
        ;;

    "test")
        echo "Testing connection and master password..."
        if check_master_password; then
            echo "✓ Authentication successful"
            echo "✓ Master password verified"
            echo "✓ IV retrieved: $CACHED_IV"

            # Test account listing
            if list_accounts > /dev/null; then
                echo "✓ Account listing successful"
            else
                echo "✗ Account listing failed"
                exit 1
            fi
        else
            echo "✗ Authentication failed"
            exit 1
        fi
        ;;

    "create")
        # Ensure we have required parameters
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi
        if [[ -z "${options["secret"]}" ]]; then
            echo "Error: --secret is required" >&2
            exit 1
        fi

        # Create account with parameters
        create_account "$account_name" \
                      "${options["secret"]}" \
                      "${options["issuer"]:-$issuer}" \
                      "${options["type"]:-totp}" \
                      "${options["digits"]:-6}" \
                      "${options["period"]:-30}" \
                      "${options["algorithm"]:-0}"

        # Cleanup session after CRUD operation
        cleanup_session
        ;;

    "update")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi
        if [[ -z "$issuer" ]]; then
            echo "Error: Issuer is required for update operations" >&2
            exit 1
        fi

        # Update account with parameters
        update_account "$account_name" \
                      "$issuer" \
                      "${options["name"]:-$account_name}" \
                      "${options["issuer"]:-$issuer}" \
                      "${options["type"]:-}" \
                      "${options["digits"]:-}" \
                      "${options["period"]:-}" \
                      "${options["algorithm"]:-}"

        # Cleanup session after CRUD operation
        cleanup_session
        ;;

    "delete")
        if [[ -z "$account_name" ]]; then
            echo "Error: Account name is required" >&2
            exit 1
        fi
        if [[ -z "$issuer" ]]; then
            echo "Error: Issuer is required for delete operations" >&2
            exit 1
        fi

        # Confirm deletion
        echo "Are you sure you want to delete account '$account_name' from '$issuer'? (y/N)"
        read -r confirmation
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            delete_account "$account_name" "$issuer"
        else
            echo "Delete cancelled"
        fi

        # Cleanup session after CRUD operation
        cleanup_session
        ;;

    "-h"|"--help")
        echo "NCOTP - Nextcloud OTP Manager CLI"
        echo ""
        echo "Usage: ncotp <command> <name> [issuer] [options]"
        echo "Not specifying issuer will return first match"
        echo ""
        echo "Commands:"
        echo "  list [--format table]   List all OTP accounts (JSON by default)"
        echo "  generate <name> <issuer> Generate OTP code for account"
        echo "  get <name> <issuer>     Get account details"
        echo "  time <name> <issuer>    Get time remaining for TOTP"
        echo "  hotp-step <name> <issuer> Manually increment HOTP counter"
        echo "  action-data <name> <issuer> Get unified action menu data (account + OTP + timing)"
        echo "  test                    Test connection and authentication"
        echo ""
        echo "Account Management:"
        echo "  create <name> --secret <secret> [options]"
        echo "                          Create new OTP account"
        echo "  update <name> <issuer> [options]"
        echo "                          Update existing account"
        echo "  delete <name> <issuer>  Delete account (with confirmation)"
        echo ""
        echo "Create/Update Options:"
        echo "  --secret <secret>       Base32 secret key (required for create)"
        echo "  --issuer <issuer>       Issuer/service name"
        echo "  --type <totp|hotp>      OTP type (default: totp, editable in update)"
        echo "  --digits <4|6>          Number of digits (default: 6)"
        echo "  --period <seconds>      TOTP period (default: 30)"
        echo "  --algorithm <0|1|2>     Hash algorithm: 0=SHA1, 1=SHA256, 2=SHA512 (default: 0)"
        echo ""
        echo "Examples:"
        echo "  ncotp list"
        echo "  ncotp generate 'Liam-Weitzel' 'Github'"
        echo "  ncotp create 'example@gmail.com' --secret 'JBSWY3DPEHPK3PXP' --issuer 'Google'"
        echo "  ncotp update 'example@gmail.com' 'Google' --digits 8"
        echo "  ncotp delete 'example@gmail.com' 'Google'"
        echo "  ncotp time 'Liam-Weitzel' 'Github'"
        ;;

    *)
        echo "NCOTP - Nextcloud OTP Manager CLI"
        echo ""
        echo "Usage: ncotp <command> <name> [issuer] [options]"
        echo ""
        echo "Commands: list, generate, get, time, hotp-step, test"
        echo ""
        echo "Use 'ncotp --help' for detailed usage information."
        ;;
esac
