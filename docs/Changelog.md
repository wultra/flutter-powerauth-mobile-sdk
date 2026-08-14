# Changelog

## 2.0.0-beta.1

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
* For all breaking changes, see the [migration guide from version 1.4.x to 2.0.x](Migration-from-1.4-to-2.0.md).

## 1.4.0

* Added `PowerAuthUtils.migrateiOSSharingConfiguration` to migrate the iOS keychain initialization flag when enabling or changing [activation data sharing](./Additional-Utilities.md#migrateiossharingconfiguration). (iOS only, no-op on Android)

## 1.3.0

* Added crypto utility functions for hash SHA256 and generation of random bytes. (see [Crypto Utilities](./Crypto-Utilities.md) for more details)

## 1.2.0

* Updated native PowerAuth Mobile SDK to version 1.9.5.
* Token-based authentication now automatically synchronizes time if needed (see [Token-Based Authentication](./Token-Based-Authentication.md) for more details)
* Logging improvements (see [Logging](./Logging.md) for more details)

## 1.1.0

* Added [additional utilities](Additional-Utilities.md) that provides `getEnvironmentInfo` with device, system and app info.
* Added the [time synchronization](Time-Synchronization.md) with the server.

## 1.0.0

* First stable release of our PowerAuth Mobile Flutter SDK – v1.0.0! 🎉
