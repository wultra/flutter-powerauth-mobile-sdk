# Changelog

## TBA

* Updates minimum supported SDK version to Flutter 3.44/Dart 3.12.
* Migrates to built-in Kotlin

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