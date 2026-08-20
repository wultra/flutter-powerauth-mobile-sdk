---
name: code-review
description: Review pull requests in the Flutter PowerAuth Mobile SDK repository. Use when reviewing Dart APIs, native bridges, security behavior, interoperability, or release changes.
---

# Flutter PowerAuth SDK review

Review only PR and repository content already available. Do not run or suggest
commands, scripts, builds, tests, linters, formatters, validation tasks, or Git
operations.

## Review contract

Use available PR metadata for the base and head. The ordinary base is `develop`;
release work targets `release/a.b.x`. Approve by default. Comment only on a
proven PR-introduced defect, naming file and line, concrete impact, and a
correction. No style, formatting, CI/workflow, hypothetical, or test-request
comments. Never post to GitHub without explicit user approval; prefix every
postable draft with `🤖`. Check grammar only in public docs/Dartdoc and only
outside a release-base PR.

Public API/behavior changes must update the relevant public documentation and
release notes. A release-to-`develop` version must be `0.0.1-dev` in every
declared version; specifically keep `pubspec.yaml` at that version on a
non-release branch.

## Product map

`flutter_powerauth_mobile_sdk_plugin` is a Flutter plugin exposing:

* `lib/flutter_powerauth_mobile_sdk_plugin.dart`, the export surface;
* `lib/src/powerauth/`, activation-code utils, crypto utils, encryptor,
  password, native-object register, and utils public/platform/method-channel
  slices;
* models under `lib/src/model/`, including `PowerAuth`, configuration,
  authentication, activation, token, password, secure-vault, encryptor, error,
  and `NativeObjectHandle` types;
* Kotlin implementation under
  `android/src/main/kotlin/com/wultra/android/powerauth/flutter/`;
* Swift implementation under
  `ios/flutter_powerauth_mobile_sdk_plugin/Sources/flutter_powerauth_mobile_sdk_plugin/`.

Unit contracts are in `test/`; real-platform coverage is in
`example/integration_test/`. Public installation and release documentation is
in `README.md`, `docs/Installation.md`, `docs/Changelog.md`, and
`CHANGELOG.md`. Release changes must also coordinate `lib/src/version.dart`;
`scripts/prepare-release.sh` may be read as tracked release logic.

## Bridge and API invariants

All Dart/native requests use the binary `MethodChannel` `powerauth_plugin`;
native logging uses `EventChannel` `com.wultra.powerauth.flutter/logging`.
Native method names are `<service>_<method>` except base `PowerAuth` methods,
which are unprefixed and route to `powerauth`.

For a native-backed API change, trace all four required layers:

1. exported public Dart API;
2. `*_platform_interface.dart` abstract contract;
3. `*_method_channel.dart` invocation using `MethodChannelHelper`; and
4. both Kotlin and Swift service handler registration and implementation.

On Android, `PowerAuthPlugin.onMethodCall` splits names and dispatches through
`PowerAuthServiceRegistry`; services register unprefixed methods. On iOS,
`PowerAuthPlugin.handle` looks up full names in its
`PowerAuthServiceRegistry`; Swift handler keys include the prefix. Flag a
change when any route, map key, nullability, result shape, error code, or
completion path differs between Dart, Android, and iOS.

`PlatformException` must map through `MethodChannelHelper` to
`PowerAuthException` with matching `PowerAuthErrorCode` names. Arguments are
plain `Map<String, dynamic>` from model `toMap()` functions: review key names,
numeric/string coercion, optional fields, and enum wire values against both
native readers. Do not serialize long-lived native SDK/password/encryptor
objects; they are opaque object-register IDs. Preserve
`NativeObjectHandle` lazy creation, explicit `release()`, and native ownership.

## Security, async, and test focus

PowerAuth state is security-sensitive: never weaken Keychain/secure storage,
biometry, password handling, activation state, signing, E2EE/encryptor,
secure-vault keys, token storage, or protocol-upgrade logic. Never log or
return passwords, activation data, private/possession keys, tokens, plaintext,
or cryptographic material. Android stateful calls must retain
`BasePowerAuthService.usePowerAuth` lifecycle behavior.

Review futures and log streams for exactly-once completion, disposal-safe event
delivery, no use-after-release, and platform-equivalent exceptions. Existing
Dart tests and Android/iOS integration scenarios may be inspected as evidence
for model, contract, and native-method changes, but never suggest running them.
Do not comment merely because CI configuration differs.
