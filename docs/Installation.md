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

Add the package from pub.dev:

```bash
flutter pub add flutter_powerauth_mobile_sdk_plugin
```

### 3. Configure Native Platforms

#### Android

Set the minimum SDK version to 23 and enable Java 17. New Flutter projects use Kotlin DSL in `android/app/build.gradle.kts`:

```kotlin
android {
    defaultConfig {
        minSdk = 23
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
```

For a project that still uses Groovy in `android/app/build.gradle`, use:

```gradle
android {
    defaultConfig {
        minSdkVersion 23
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
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

If the application uses Face ID for biometric authentication, add a user-facing usage description to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to authenticate.</string>
```

Replace the example text with a description appropriate for your application. iOS requires this key before an application can access Face ID.

### 4. Initialize PowerAuth in Dart

In your main Dart file or wherever needed:

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

final powerAuth = PowerAuth("my-instance-id");
```

## Read Next

- [Configuration](./Configuration.md)
