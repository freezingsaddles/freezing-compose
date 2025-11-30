#!/usr/bin/env bash
#
# clear-cache-directories.sh
#
# Clears the cache directories used by the application.
#
# Use this at the start of the season.

set -euo pipefail
IFS=$'\n\t'

DEBUG=${DEBUG:-false}

# Thanks https://stackoverflow.com/a/17805088
$DEBUG && export PS4='${LINENO}: ' && set -x

# Thanks https://askubuntu.com/a/15856
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

# Thanks https://stackoverflow.com/a/246128/424301
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CACHE_DIR="$SCRIPT_DIR"/../sync-data/cache

DIRS_TO_CLEAR=(
    "activities"
    "weather"
)

for DIR_NAME in "${DIRS_TO_CLEAR[@]}"; do
    TARGET_DIR="$CACHE_DIR/$DIR_NAME"
    if [[ -d "$TARGET_DIR" ]]; then
        echo "Clearing cache directory: $TARGET_DIR"
        rm -rf "$TARGET_DIR"
        mkdir -p "$TARGET_DIR"
    else
        echo "Cache directory does not exist, skipping: $TARGET_DIR"
    fi
done
