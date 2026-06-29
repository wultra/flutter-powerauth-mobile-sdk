#!/bin/bash

set -e # stop script when error occurs
set -u # stop when undefined variable is used

# Optional command tracing can be enabled with PA_DEBUG_INTEGRATION=1.
if [ "${PA_DEBUG_INTEGRATION:-0}" = "1" ]; then
  set -x
fi

is_simulator_booted() {
  sim_id="$1"
  xcrun simctl list devices | grep -F "$sim_id" | grep -Fq "(Booted)"
}

boot_simulator() {
  sim_id="$1"
  if boot_output=$(xcrun simctl boot "$sim_id" 2>&1); then
    return 0
  fi

  if printf '%s\n' "$boot_output" | grep -Fq "current state: Booted"; then
    echo "Simulator $sim_id is already booted."
    return 0
  fi

  echo "ERROR: Failed to boot simulator $sim_id." >&2
  echo "$boot_output" >&2
  return 1
}

is_verbose_mode() {
  case "${PA_FLUTTER_TEST_VERBOSE:-0}" in
    1|true|TRUE)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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

# reset only selected simulator to avoid stale boot sessions that can break VM attach
if is_simulator_booted "$SIM_ID"; then
  echo "Simulator $SIM_ID is booted, shutting it down first."
  xcrun simctl shutdown "$SIM_ID"
else
  echo "Simulator $SIM_ID is already shutdown."
fi

# open the Simulator app focused on selected device and boot it
open -a Simulator --args -CurrentDeviceUDID "$SIM_ID"
boot_simulator "$SIM_ID"

# wait until the simulator is fully booted before launching tests, otherwise
# the app launch / VM service attach can stall indefinitely
xcrun simctl bootstatus "$SIM_ID" -b

(
  cd "$SCRIPT_FOLDER/../example"
  (
    cd ios
    pod install # install pods to shave some time off the test run
  )

  wait_for_flutter_device "$SIM_ID"

  set -- --no-pub -d "$SIM_ID" -r expanded integration_test/plugin_integration_test.dart --timeout 20m
  if is_verbose_mode; then
    set -- -v "$@"
  fi

  flutter test "$@"
)
