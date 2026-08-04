# Installation

## Supported Platforms

The library is available for the following __Flutter 3.44.0+ and Dart 3.12.0+__ platforms:

- __Android 6.0 (API 23)__ and newer
- __iOS 13.4__ and newer

## How To Install

### 1. Prerequisites

- Flutter SDK installed ([Get Started](https://flutter.dev/docs/get-started/install))
- A working Flutter project (`flutter create my_app` if starting fresh)

### 2. Add Dependency

For a released version, add the package from pub.dev:

```bash
flutter pub add flutter_powerauth_mobile_sdk_plugin
```

This documentation describes the upcoming 2.0 API. After version 2.0 is published, the equivalent explicit constraint is:

```yaml
dependencies:
  flutter_powerauth_mobile_sdk_plugin: ^2.0.0
```

While testing the unreleased development version, reference the required Git revision explicitly instead of using the unpublished version constraint:

```yaml
dependencies:
  flutter_powerauth_mobile_sdk_plugin:
    git:
      url: https://github.com/wultra/flutter-powerauth-mobile-sdk.git
      ref: develop
```

Pin a commit or release tag for reproducible application builds. Then run:

```bash
flutter pub get
```

### 3. Configure Native Platforms

#### Android

In `android/app/build.gradle`, make sure to set the minimum SDK version:

```gradle
minSdkVersion 23
```

Also, make sure to enable Java 17:

```gradle
compileOptions {
    sourceCompatibility JavaVersion.VERSION_17
    targetCompatibility JavaVersion.VERSION_17
}
```

#### iOS

In `ios/Podfile`, ensure the platform version is at least 13.4 when the project uses CocoaPods:

```ruby
platform :ios, '13.4'
```

Then install pods:

```bash
cd ios
pod install
cd ..
```

Flutter projects configured to use Swift Package Manager consume the plugin's package integration automatically; do not add the native `PowerAuth2` package separately.

### 4. Initialize PowerAuth in Dart

In your main Dart file or wherever needed:

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

final powerAuth = PowerAuth("my-instance-id");
```

## Read Next

- [Configuration](./Configuration.md)
