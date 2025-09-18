# Installation

## Supported Platforms

The library is available for the following __Flutter 3.3.0+__ platforms:

- __Android 5.0 (API 21)__ and newer
- __iOS 13.4__ and newer

## How To Install

### 1. Prerequisites

- Flutter SDK installed ([Get Started](https://flutter.dev/docs/get-started/install))
- A working Flutter project (`flutter create my_app` if starting fresh)

### 2. Add Dependency

Open `pubspec.yaml` and add:

```yaml
dependencies:
  flutter_powerauth_mobile_sdk_plugin: ^1.3.0  # Check pub.dev for latest version
```

Then run:

```bash
flutter pub get
```

### 3. Configure Native Platforms

#### Android

In `android/app/build.gradle`, make sure to set the minimum SDK version:

```gradle
minSdkVersion 21
```

Also, make sure to enable Java 11:

```gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_11
    targetCompatibility JavaVersion.VERSION_11
}
```

#### iOS

In `ios/Podfile`, ensure the platform version is at least 13.4:

```ruby
platform :ios, '13.4'
```

Then install pods:

```bash
cd ios
pod install
cd ..
```

#### 4. Initialize PowerAuth in Dart

In your main Dart file or wherever needed:

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

final powerAuth = PowerAuth("my-instance-id);
```

## Read Next

- [Configuration](./Configuration.md)
