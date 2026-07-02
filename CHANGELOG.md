## TBA

* The `configuration` property was changed to asynchronous
* The `clientConfiguration`, `biometryConfiguration`, `keychainConfiguration` and `sharingConfiguration` were removed without replacement
* PowerAuth configuration now outlives the Dart hot-restart feature [(#70)](https://github.com/wultra/flutter-powerauth-mobile-sdk/issues/70).

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
