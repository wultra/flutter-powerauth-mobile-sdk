## TBA

- TBA

## 2.0.0

* Updated the native PowerAuth Mobile SDK dependencies to version 2.0.
* Added PowerAuth protocol 4.0 algorithms and authenticated protocol upgrade support.
* Added new APIs for digital and JWS signatures, certificate signing requests, device public-key export, biometric status, and Secure Vault keys.
* Replaced password change with the two-step `beginPasswordChange()` and `finishPasswordChange()` API.
* Replaced request-signature methods with `authenticationHeaderForRequestWithParams()` and `authenticationHeaderForRequestWithBody()`.
* Changed end-to-end encryption to use a single-use `PowerAuthEncryptor` for each request and response exchange.
* Changed binary input and output from encoded strings to `Uint8List`.
* Updated the minimum supported SDK version to Flutter 3.44 and Dart 3.12.
* Updated the minimum supported Android version to Android 6.0 (API 23).
* Migrated to built-in Kotlin.
* Changed the `configuration` property to an asynchronous property.
* Changed the `clientConfiguration`, `biometryConfiguration`, `keychainConfiguration`, and `sharingConfiguration` properties to asynchronous properties that return the effective native configurations.
* PowerAuth configuration now outlives the Dart hot-restart feature [(#70)](https://github.com/wultra/flutter-powerauth-mobile-sdk/issues/70).
* Fixed parsing the `address` claim in `PowerAuthUserInfo` when received from the native platform.
* For all breaking changes, see the [migration guide from version 1.4.x to 2.0.x](docs/Migration-from-1.4-to-2.0.md).

## 1.4.0

* Added `PowerAuthUtils.migrateiOSSharingConfiguration` to migrate the iOS keychain initialization flag when enabling or changing activation data sharing (iOS only, no-op on Android).

## 1.3.0

* Added crypto utility functions for hash SHA256 and generation of random bytes.

## 1.2.0

* Updated native PowerAuth Mobile SDK to version 1.9.5.
* Token-based authentication now automatically synchronizes time if needed.
* Logging improvements.

## 1.1.0

* Added `PowerAuthUtils` that provides `getEnvironmentInfo` with device, system and app info.
* Added `PowerAuthTimeSynchronizationService` that provides time synchronization with the server.

## 1.0.0

* First stable release of our PowerAuth Mobile Flutter SDK – v1.0.0! 🎉

## 1.0.0-beta.5

* Fixed issue on Android when the plugin was invoked from multiple isolates
* Improved biometrics handling

## 1.0.0-beta.4

* Added End-to-End Encryption support.
* Introduced token-based authentication.
* OIDC activation.
* Enabled group authentication functionality.
* Added data signing using the device's private key.
* Implemented encryption key retrieval.
* Added User Info feature.
* Added `PowerAuthDebug` features.
* Enhanced overall stability and internal improvements.

## 1.0.0-beta.3

* Fixed crash on iOS when the device was offline.

## 1.0.0-beta.2

* Advanced PowerAuth configuration.
* Fixed bugs with biometrics on the Android platform.
* Improved stability and internals.

## 1.0.0-beta.1

* Initial beta release of the SDK.
