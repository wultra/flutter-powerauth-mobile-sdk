#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
#set -x # print all execution (good for debugging)

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# list available iOS Simulators
xcrun simctl list devices available

# get the first available iOS Simulator ID
SIM_ID=$(xcrun simctl list devices available | grep 'iPhone' | head -n 1 | grep -oE '[A-F0-9-]{36}')

# fail fast if no iOS simulator is available
if [ -z "$SIM_ID" ]; then
  echo "ERROR: No available iPhone simulator found." >&2
  exit 1
fi

echo "Booting iOS Simulator with ID: $SIM_ID"

# open the Simulator app and boot the simulator
open -a Simulator
xcrun simctl boot "$SIM_ID" || true

# wait until the simulator is fully booted before launching tests, otherwise
# the app launch / VM service attach can stall indefinitely
xcrun simctl bootstatus "$SIM_ID" -b

pushd "$SCRIPT_FOLDER/../example"
pushd "ios"
pod install # install pods to shave some time off the test run
popd
flutter test -d "$SIM_ID" -r expanded integration_test/plugin_integration_test.dart --timeout 20m
popd
