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

The plugin supports both Swift Package Manager (SwiftPM) and CocoaPods. The Dart dependency added in step 2 is the same for either option.

##### Swift Package Manager

Flutter 3.44 and newer enable SwiftPM by default. To install the plugin in an iOS app:

1. Open `ios/Runner.xcworkspace` in Xcode. Select the `Runner` target and set **Minimum Deployments** to iOS 13.4 or newer.
2. If you changed the deployment target, regenerate the iOS configuration with `flutter build ios --config-only`.
3. Run the app with `flutter run` on an iOS simulator or device. Flutter adds `FlutterGeneratedPluginSwiftPackage` to the Xcode project and resolves the plugin's native `PowerAuth2` dependency through SwiftPM.

You can check the integration in Xcode under **Package Dependencies**: `FlutterGeneratedPluginSwiftPackage` should be present. Flutter manages the plugin and its native dependencies, so there is no need to add this repository or `PowerAuth2` as a separate Xcode package.

If SwiftPM was previously disabled, run `flutter config --enable-swift-package-manager` and remove any `enable-swift-package-manager: false` setting from the `flutter.config` section of your app's `pubspec.yaml`. Flutter may still use CocoaPods for other plugins that do not support SwiftPM. See [Flutter's SwiftPM guide](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers) for details.

##### CocoaPods

If your project uses CocoaPods, ensure the platform version in `ios/Podfile` is at least 13.4:

```ruby
platform :ios, '13.4'
```

Then install pods:

```bash
cd ios
pod install
cd ..
```

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
