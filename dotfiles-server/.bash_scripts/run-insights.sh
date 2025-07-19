#!/usr/bin/env bash
set -euo pipefail

CACHE_FILE="/tmp/insights_include_paths.cache"

if [[ -f "$CACHE_FILE" ]]; then
  # Load cached paths
  source "$CACHE_FILE"
else
  # Resolve paths dynamically
  LIBCXX_INCLUDE="$(nix eval --raw nixpkgs#llvmPackages.libcxx.dev.outPath)/include/c++/v1"
  GLIBC_INCLUDE="$(nix eval --raw nixpkgs#glibc.dev.outPath)/include"
  CLANG_RESOURCE_INCLUDE="$(clang++ -print-resource-dir)/include"

  # Save to cache file
  cat > "$CACHE_FILE" << EOF
LIBCXX_INCLUDE="$LIBCXX_INCLUDE"
GLIBC_INCLUDE="$GLIBC_INCLUDE"
CLANG_RESOURCE_INCLUDE="$CLANG_RESOURCE_INCLUDE"
EOF
fi

COMPILE_COMMANDS="${1}"

if [[ ! -f "$COMPILE_COMMANDS" ]]; then
  echo "Error: compile_commands.json not found at $COMPILE_COMMANDS"
  exit 1
fi

declare -A INCLUDE_PATHS=()

# Extract all compile commands
mapfile -t commands < <(jq -r '.[].command' "$COMPILE_COMMANDS")

for cmd in "${commands[@]}"; do
  # Split command into tokens safely using readarray + xargs trick
  while read -r flag; do
    case $flag in
      -I*)
        path="${flag#-I}"
        INCLUDE_PATHS["$path"]=1
        ;;
      -isystem)
        # Next token is path
        read -r path
        INCLUDE_PATHS["$path"]=1
        ;;
    esac
  done < <(echo "$cmd" | xargs -n1)
done

# Build flags from extracted includes
INCLUDE_FLAGS=""
for path in "${!INCLUDE_PATHS[@]}"; do
  INCLUDE_FLAGS+=" -I${path}"
done

# Add your fixed includes + system includes
CXX_FLAGS="-std=c++17 -stdlib=libc++ \
  $INCLUDE_FLAGS \
  -isystem $LIBCXX_INCLUDE \
  -isystem $GLIBC_INCLUDE \
  -isystem $CLANG_RESOURCE_INCLUDE"

# Run insights with the flags and passed arguments
insights "$@" -- $CXX_FLAGS
