#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used
set -o pipefail # fail a pipeline if any command in it fails, not just the last

is_simulator_booted() {
  sim_id="$1"
  xcrun simctl list devices | grep -F "$sim_id" | grep -Fq "(Booted)"
}

wait_for_flutter_device() {
  sim_id="$1"
  max_attempts=30
  delay_seconds=2
  attempt=1

  while [ "$attempt" -le "$max_attempts" ]; do
    if flutter devices --machine | grep -Fq "$sim_id"; then
      echo "Simulator $sim_id is visible to Flutter (attempt $attempt/$max_attempts)."
      return 0
    fi

    sleep "$delay_seconds"
    attempt=$((attempt + 1))
  done

  echo "ERROR: Simulator $sim_id did not appear in Flutter device list in time." >&2
  flutter devices >&2 || true
  return 1
}

# path to the script folder
SCRIPT_FOLDER=$( cd "$( dirname "$0" )" && pwd )

# get the first available iOS Simulator ID from iOS runtimes
SIM_LINE=$(xcrun simctl list devices available iOS | grep -m 1 'iPhone' || true)
SIM_ID=$(printf '%s\n' "$SIM_LINE" | sed -nE 's/.*\(([A-F0-9-]{36})\).*/\1/p')

# fail fast if no iOS simulator is available
if [ -z "$SIM_ID" ]; then
  echo "ERROR: No available iPhone simulator found." >&2
  exit 1
fi

echo "Selected iOS simulator: $SIM_LINE"
echo "Booting iOS Simulator with ID: $SIM_ID"

# ensure the selected simulator is shut down when the script exits (success or failure)
trap 'xcrun simctl shutdown "$SIM_ID" >/dev/null 2>&1 || true' EXIT

# shut down only the selected simulator to clear any stale boot session that can break VM service attach
if is_simulator_booted "$SIM_ID"; then
  echo "Simulator $SIM_ID is booted, shutting it down first."
  xcrun simctl shutdown "$SIM_ID"
else
  echo "Simulator $SIM_ID is already shutdown."
fi

# boot the simulator and wait until it is fully booted before launching tests,
# otherwise the app launch / VM service attach can stall indefinitely
xcrun simctl bootstatus "$SIM_ID" -b -t 300

(
  cd "$SCRIPT_FOLDER/../example"
  (
    cd ios
    pod install # install pods to shave some time off the test run
  )

  wait_for_flutter_device "$SIM_ID"

  flutter test --no-pub -d "$SIM_ID" -r expanded integration_test/plugin_integration_test.dart --timeout 30m
)
