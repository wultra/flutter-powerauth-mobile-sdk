#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "${SCRIPT_DIRECTORY}/.." && pwd)

cd "${REPOSITORY_ROOT}"

command -v dart >/dev/null 2>&1 || { echo "dart is required to format Dart sources." >&2; exit 1; }
command -v swift >/dev/null 2>&1 || { echo "swift-format is required to format Swift sources." >&2; exit 1; }
command -v ktlint >/dev/null 2>&1 || { echo "ktlint is required to format Kotlin sources." >&2; exit 1; }

dart format lib test example/lib example/test example/integration_test

swift format format \
    --configuration .swift-format \
    --recursive \
    --parallel \
    --in-place \
    ios/flutter_powerauth_mobile_sdk_plugin/Package.swift \
    ios/flutter_powerauth_mobile_sdk_plugin/Sources \
    example/ios/Runner \
    example/ios/RunnerTests

ktlint --format --relative \
    'android/**/*.kt' \
    'android/**/*.kts' \
    'example/android/**/*.kt' \
    'example/android/**/*.kts'
