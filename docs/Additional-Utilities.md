# Additional Utilities

The PowerAuth Flutter SDK offers additional utility functions that can help with various tasks in your application. These utilities are available through the `PowerAuthUtils` class.

## Available Methods

### `getEnvironmentInfo()`

Returns information about the current environment, including system details, device information, and SDK version.

**Usage:**

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

final envInfo = await PowerAuthUtils.getEnvironmentInfo();
print("Device manufacturer: ${envInfo.deviceManufacturer}");
```

**Response:**

The method returns a `PowerAuthEnvironmentInfo` object with the following properties:

- `systemName` (string): System name, for example "iOS", "Android", "iPadOS"
- `systemVersion` (string): Version of the system
- `applicationVersion` (string, optional): Application version, e.g. "1.0.0"
- `applicationIdentifier` (string, optional): Host application identifier, for example "com.wultra.demoapp"
- `deviceManufacturer` (string): Device manufacturer, for example "apple" or "Samsung"
- `deviceId` (string): Device ID, for example "iPhone9,2"
- `sdkVersion` (string): PowerAuth Flutter SDK version, for example "1.0.0"

### `migrateiOSSharingConfiguration()`

Migrates the iOS keychain initialization state between two [activation data sharing](Configuration.md) setups. **This method is iOS-only and is a no-op on Android.**

> [!IMPORTANT]
> Use this method only after consulting Wultra support or engineers. Incorrect usage can lead to scenarios where users lose access to their activation data.

**Why is this needed?**

PowerAuth SDK for iOS keeps track of whether the application has been reinstalled. When you start sharing activation data between your application and its extension (or when you change the app group used for sharing), this state must be moved to the new setup. Otherwise the SDK may evaluate the locally stored activation incorrectly after the configuration change.

This mechanism mirrors the native [UserDefaults migration](https://developers.wultra.com/components/powerauth-mobile-sdk/1.9.x/documentation/PowerAuth-SDK-for-iOS-Extensions#userdefaults-migration) described in the PowerAuth SDK for iOS Extensions documentation.

> [!IMPORTANT]
> Call this method at the application's startup, **before** any `PowerAuth` instance is configured and used.

**Usage:**

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

await PowerAuthUtils.migrateiOSSharingConfiguration(
  from: previousConfiguration,
  to: sharedConfiguration,
);
```

**Parameters:**

- `from` (`PowerAuthSharingConfiguration?`): the source configuration to migrate from.
- `to` (`PowerAuthSharingConfiguration?`): the destination configuration to migrate to.

**Validation:**

The method throws an `ArgumentError` when:

- both `from` and `to` are `null`, or
- both are provided but share the same `appGroup` (there would be nothing to migrate).

## Read Next

- [Crypto Utilities](Crypto-Utilities.md)