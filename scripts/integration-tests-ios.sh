#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
# stop on errors in pipelines if supported by the active shell
(set -o pipefail) 2>/dev/null && set -o pipefail

# Optional command tracing can be enabled with PA_DEBUG_INTEGRATION=1.
if [ "${PA_DEBUG_INTEGRATION:-0}" = "1" ]; then
  set -x
fi

print_section() {
  echo
  echo "========== $1 =========="
}

wait_for_flutter_device() {
  sim_id="$1"
  max_attempts=30
  delay_seconds=2
  attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    if flutter devices --machine | grep -q "$sim_id"; then
      echo "Simulator $sim_id is visible to Flutter (attempt $attempt/$max_attempts)."
      return 0
    fi

    sleep "$delay_seconds"
    attempt=$((attempt + 1))
  done

  echo "ERROR: Simulator $sim_id did not appear in Flutter device list in time." >&2
  return 1
}

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "$0" )" && pwd )

print_section "Host / toolchain"
sw_vers
xcodebuild -version
flutter --version
flutter doctor -v

# list available iOS Simulators
print_section "Available iOS simulators"
xcrun simctl list devices available
xcrun simctl list runtimes

# get the first available iOS Simulator ID from iOS runtimes
SIM_LINE=$(xcrun simctl list devices available iOS | grep 'iPhone' | head -n 1 || true)
SIM_ID=$(echo "$SIM_LINE" | grep -oE '[A-F0-9-]{36}' || true)

# fail fast if no iOS simulator is available
if [ -z "$SIM_ID" ]; then
  echo "ERROR: No available iPhone simulator found." >&2
  exit 1
fi

echo "Selected iOS simulator: $SIM_LINE"
echo "Booting iOS Simulator with ID: $SIM_ID"

print_section "Reset selected simulator state"
# reset only selected simulator to avoid stale boot sessions that can break VM attach
xcrun simctl shutdown "$SIM_ID" || true

# open the Simulator app focused on selected device and boot it
open -a Simulator --args -CurrentDeviceUDID "$SIM_ID"
xcrun simctl boot "$SIM_ID"

# wait until the simulator is fully booted before launching tests, otherwise
# the app launch / VM service attach can stall indefinitely
xcrun simctl bootstatus "$SIM_ID" -b
xcrun simctl list devices | grep "$SIM_ID"

pushd "$SCRIPT_FOLDER/../example"
pushd "ios"
pod install # install pods to shave some time off the test run
popd
print_section "Flutter-visible devices"
flutter devices
flutter devices -v
wait_for_flutter_device "$SIM_ID"
print_section "Running iOS integration tests (verbose)"
flutter test -v --no-pub -d "$SIM_ID" -r expanded integration_test/plugin_integration_test.dart --timeout 20m
popd
