# Copilot instructions

Flutter plugin (`flutter_powerauth_mobile_sdk_plugin`) that bridges the native PowerAuth Mobile SDKs (Android/Kotlin, iOS/Swift) to Dart. It is a **federated plugin** using `plugin_platform_interface`. See `.github/CONTRIBUTING.md` for the full developer guide.

## Build, test, and analyze

- **Analyze (lint):** `flutter analyze --fatal-warnings` (CI uses `--fatal-warnings`; baseline must be clean before a PR).
- **Unit tests:** `flutter test` (Dart-only tests in `test/`).
  - Single file: `flutter test test/configuration_objects_test.dart`
  - Single test by name: `flutter test --plain-name "<substring of test name>"`
- **Integration tests** (real device/simulator, in `example/`): `cd example && flutter test -r expanded integration_test/plugin_integration_test.dart`
  - Requires `example/.env` (copy from `example/.env-example`; values come from the Wultra/your team). The entry file aggregates all suites in `example/integration_test/suites/`.
  - iOS via script: `sh ./scripts/integration-tests-ios.sh`. Both platforms also need `flutter pub get` in `example/` (and `pod install` in `example/ios/` for iOS).

## Architecture: how a call flows

All Dart ⇆ native communication goes over a **single `MethodChannel` named `powerauth_plugin`** (binary-encoded). A separate `EventChannel` `com.wultra.powerauth.flutter/logging` streams native logs.

Each feature exists as a **plugin/service slice present in 4 layers** — when adding or changing a native-backed method, touch all of them:

1. **Public API** — e.g. `lib/src/powerauth/powerauth.dart` (`PowerAuth`), `powerauth_password/`, `powerauth_utils/`. These classes hold an `instanceId` and **delegate every call** to `PowerAuthPlatform.instance`.
2. **Platform interface** — `*_platform_interface.dart` (e.g. `powerauth_platform_interface.dart`): abstract `extends PlatformInterface`, each method body is `throw UnimplementedError(...)`.
3. **Method channel impl** — `*_method_channel.dart`: concrete class `with MethodChannelHelper`; calls `invokeMethod` / `invokeNullableMethod` from `lib/src/utils/method_channel_helper.dart`.
4. **Native services** — Android `android/src/main/kotlin/.../internal/services/*.kt` and iOS `ios/Classes/internal/services/*.swift`, registered in `PowerAuthServiceRegistry` on each platform.

The public exports surface is `lib/flutter_powerauth_mobile_sdk_plugin.dart` — add new public types there.

## Native method routing convention (critical)

Method-channel method names use the format **`<service>_<method>`** (camelCase method), e.g. `util_parseActivationCode`, `password_create`. Base `PowerAuth` methods have **no prefix** (e.g. `configure`, `hasValidActivation`) and route to the `powerauth` service.

- **Android** (`PowerAuthPlugin.onMethodCall`): splits the method name on the first `_` → `serviceName` + `methodName`; no underscore ⇒ service `powerauth`. Looks up `serviceRegistry[serviceName].handlers[methodName]`. Each service sets `override val name` (the prefix) and exposes a `handlers` map of `methodName -> ::function`.
- **iOS** (`PowerAuthPlugin.handle`): looks up the **full** method string in `PowerAuthServiceRegistry.handlers`, so each Swift service's `handlers` map is keyed by the full name (e.g. `"util_parseActivationCode"`).

So a new native method must be registered in **both** the Kotlin service `handlers` map **and** the Swift service `handlers` map, and both registries (`PowerAuthServiceRegistry`) must include the service.

## Conventions

- **Errors:** native `PlatformException`s are mapped to `PowerAuthException` (`lib/src/model/powerauth_error.dart`) in `MethodChannelHelper`, matching `e.code` to `PowerAuthErrorCode` by name. Keep error codes consistent across Dart/Kotlin/Swift.
- **Native object handles:** long-lived native objects (SDK instances, passwords, encryptors) are passed as opaque IDs via a `PowerAuthObjectRegister` / `NativeObjectRegister` rather than serialized. Android services extend `BasePowerAuthService` and use `usePowerAuth { sdk -> ... }` to resolve an instance by `instanceId`.
- **Model serialization:** model classes implement `toMap()`; arguments are plain `Map<String, dynamic>` matching the keys read on the native side.
- **License header:** every source file (Dart/Kotlin/Swift) starts with the Apache 2.0 header (`Copyright <year> Wultra s.r.o.`). Copy it into new files.
- **`avoid_print` is intentionally disabled** in `analysis_options.yaml` (temporary, pending a logger).

## Releases & branching

- Branch from and PR into **`develop`**; release streams are `release/a.b.x` with linear history. Branch naming: `issues/<number>-short-description`.
- A version bump must update **all** of: `pubspec.yaml`, `lib/src/version.dart`, `CHANGELOG.md`, `docs/Changelog.md`, `docs/Installation.md` (and `docs/PowerAuth-Server-Compatibility.md` if relevant). Use `scripts/prepare-release.sh` (pass `--verify` to check consistency). See CONTRIBUTING "Preparing a New Release".
