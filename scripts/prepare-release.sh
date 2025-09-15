#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

######### USAGE #########
# This script prepares the release of the Flutter package by running the JavaScript script from Wultra infrastructure repository.
# It can be run in 3 modes:
# 1. With a version argument: it will prepare the release with the current version in the pubspec.yaml file.
#    Example: sh scripts/prepare-release.sh 1.0.0
# 2. With a version argument and --verify: it will verify that the given release version is prepared.
#    Example: sh scripts/prepare-release.sh 1.0.0 --verify
# 3. Without arguments: it will run the script in the root directory of the repository and verify that all files are prepared.
#    Example: sh scripts/prepare-release.sh
#########################

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# URL of the JavaScript prepare-release script in Wultra infrastructure repository
URL="https://raw.githubusercontent.com/wultra/wultra-infrastructure/refs/heads/mobile-release/mobile-release/v1/prepare-release.js"

# Create a temporary file
TMP_FILE=$(mktemp)

# Ensure the temporary file is removed on exit
trap 'rm -f "$TMP_FILE"' EXIT

# Download the file
echo "Downloading prepare-release.js script from Wultra infrastructure repository..."
curl -fsSL "$URL" -o "$TMP_FILE"

# Run the file with Node.js in a root directory of the repository
COMMAND="node $TMP_FILE -p $SCRIPT_FOLDER/.." # --ignore-git-clean" # uncomment to ignore git clean errors
if [ $# -ge 1 ]; then
  COMMAND="$COMMAND -v $1"
fi
if [[ $# -ge 2 && "$2" == "--verify" ]]; then
  COMMAND="$COMMAND --verify"
fi
echo "Executing command: $COMMAND"
eval "$COMMAND"