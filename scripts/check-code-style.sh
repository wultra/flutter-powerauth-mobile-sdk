#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "${SCRIPT_DIRECTORY}/.." && pwd)

cd "${REPOSITORY_ROOT}"

command -v dart >/dev/null 2>&1 || { echo "dart is required to check Dart sources." >&2; exit 1; }
command -v swift >/dev/null 2>&1 || { echo "swift-format is required to check Swift sources." >&2; exit 1; }
command -v swiftlint >/dev/null 2>&1 || { echo "SwiftLint is required to lint Swift sources." >&2; exit 1; }
command -v ktlint >/dev/null 2>&1 || { echo "ktlint is required to check Kotlin sources." >&2; exit 1; }

dart format \
    --output=none \
    --set-exit-if-changed \
    lib test example/lib example/test example/integration_test

swift format lint \
    --configuration .swift-format \
    --recursive \
    --parallel \
    --strict \
    ios/flutter_powerauth_mobile_sdk_plugin/Package.swift \
    ios/flutter_powerauth_mobile_sdk_plugin/Sources \
    example/ios/Runner \
    example/ios/RunnerTests

swiftlint lint \
    --strict \
    --no-cache \
    --config .swiftlint.yml

ktlint --relative \
    'android/**/*.kt' \
    'android/**/*.kts' \
    'example/android/**/*.kt' \
    'example/android/**/*.kts'
