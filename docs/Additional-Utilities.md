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
