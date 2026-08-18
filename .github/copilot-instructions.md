# Copilot instructions

`flutter_powerauth_mobile_sdk_plugin` bridges the native PowerAuth Mobile SDKs (Android/Kotlin and iOS/Swift) to Dart. It uses `plugin_platform_interface`; see `.github/CONTRIBUTING.md` for the contributor and release workflow.

## Build, test, and analyze

- Fetch root-package dependencies with `flutter pub get`.
- **Analyze (lint):** `flutter analyze --fatal-warnings` (CI uses `--fatal-warnings`; baseline must be clean before a PR).
- **Unit tests:** `flutter test` (Dart-only tests in `test/`).
  - Single file: `flutter test test/configuration_objects_test.dart`
  - Single test by name: `flutter test --plain-name "<substring of test name>"`
- **Integration tests** (real device/simulator, in `example/`): `cd example && flutter test -r expanded integration_test/plugin_integration_test.dart`
  - Requires `example/.env` (copy `example/.env-example`) and `flutter pub get` in `example/`. The entry file aggregates the suites in `example/integration_test/suites/`; select a device with `-d <device-id>`.
  - iOS simulator: from the repository root, run `bash scripts/integration-tests-ios.sh`. The script uses Swift Package Manager and runs `xcodebuild test`.

## Architecture: how a call flows

All Dart ⇆ native communication goes over a **single `MethodChannel` named `powerauth_plugin`** (binary-encoded). A separate `EventChannel` `com.wultra.powerauth.flutter/logging` streams native logs.

Each feature exists as a **plugin/service slice present in 4 layers** — when adding or changing a native-backed method, touch all of them:

1. **Public API** — e.g. `lib/src/powerauth/powerauth.dart` (`PowerAuth`), `powerauth_password/`, and `powerauth_utils/`. Stateful APIs hold an `instanceId` and delegate calls to their platform interface.
2. **Platform interface** — `*_platform_interface.dart` (e.g. `powerauth_platform_interface.dart`): abstract `extends PlatformInterface`, each method body is `throw UnimplementedError(...)`.
3. **Method channel impl** — `*_method_channel.dart`: concrete class `with MethodChannelHelper`; calls `invokeMethod` / `invokeNullableMethod` from `lib/src/utils/method_channel_helper.dart`.
4. **Native services** — Android `android/src/main/kotlin/.../internal/services/*.kt` and iOS `ios/flutter_powerauth_mobile_sdk_plugin/Sources/flutter_powerauth_mobile_sdk_plugin/internal/services/*.swift`, registered in each platform's `PowerAuthServiceRegistry`.

The public exports surface is `lib/flutter_powerauth_mobile_sdk_plugin.dart` — add new public types there.

## Native method routing convention (critical)

Method-channel method names use the format **`<service>_<method>`** (camelCase method), e.g. `util_parseActivationCode`, `password_create`. Base `PowerAuth` methods have **no prefix** (e.g. `configure`, `hasValidActivation`) and route to the `powerauth` service.

- **Android** (`PowerAuthPlugin.onMethodCall`): no underscore means service `powerauth`; otherwise the service and method are the portions before and after the underscore. It looks up `serviceRegistry[serviceName].handlers[methodName]`. Each service sets `override val name` (the prefix) and uses unprefixed `methodName -> ::function` entries.
- **iOS** (`PowerAuthPlugin.handle`): looks up the **full** method string in `PowerAuthServiceRegistry.handlers`, so each Swift service's `handlers` entries include the prefix (for example, `"util_parseActivationCode"`).

So a new native method must be registered in **both** the Kotlin service `handlers` map **and** the Swift service `handlers` map, and both registries (`PowerAuthServiceRegistry`) must include the service.

## Conventions

- **Errors:** native `PlatformException`s are mapped to `PowerAuthException` (`lib/src/model/powerauth_error.dart`) in `MethodChannelHelper`, matching `e.code` to `PowerAuthErrorCode` by name. Keep error codes consistent across Dart/Kotlin/Swift.
- **Native object handles:** long-lived native objects (SDK instances, passwords, encryptors) are opaque IDs managed by `PowerAuthObjectRegister` / `NativeObjectRegister`, not serialized. `NativeObjectHandle` supports lazy creation and explicit `release()`; APIs that consume a handle must preserve its release semantics. Android stateful services extend `BasePowerAuthService` and resolve an instance through `usePowerAuth { sdk -> ... }`.
- **Model serialization:** model classes implement `toMap()`; arguments are plain `Map<String, dynamic>` matching the keys read on the native side.
- **License header:** every source file (Dart/Kotlin/Swift) starts with the Apache 2.0 header (`Copyright <year> Wultra s.r.o.`). Copy it into new files.
- **`avoid_print` is intentionally disabled** in `analysis_options.yaml` (temporary, pending a logger).

## Releases & branching

- Branch from and PR into **`develop`**; release streams are `release/a.b.x` with linear history. Branch naming: `issues/<number>-short-description`.
- On non-release branches, keep the development version as `0.0.1-dev` (including in `pubspec.yaml`).
- A version bump must update **all** of: `pubspec.yaml`, `lib/src/version.dart`, `CHANGELOG.md`, `docs/Changelog.md`, `docs/Installation.md` (and `docs/PowerAuth-Server-Compatibility.md` if relevant). Use `scripts/prepare-release.sh` (pass `--verify` to check consistency). See CONTRIBUTING "Preparing a New Release".
