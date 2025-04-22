# Flutter PowerAuth dev-ving

This is an internal Wultra-dev doc aimed at anyone interested in setting up a Flutter environment for the reading / contributing to the plugin SDK.

Links to full docs: 

# Flutter installation

Full docs [here](https://docs.flutter.dev/get-started/install/macos). Our SDK is targetting `Android` and `iOS` only.

! `flutter doctor` is an awesome tool to check, troubleshoot, and get recommended version upgrades for your setup.

* `Rosetta` is required for parts of Flutter. Run `sudo softwareupdate --install-rosetta --agree-to-license`
* Have `Xcode 16+`, `CocoaPods` set up with `v1.16+` (`sudo gem install cocoapods`) installed (or `Bundler` set up) 
* Have `Android Studio 2024.1 (Koala)+` with `Flutter plugin`, set up and install all Android-dev related stuff (SDK Platforms, cmd tools, build tools, emulator). There are no Flutter-specifics, so continue if you have the "standard" install. Full docs [here](https://docs.flutter.dev/get-started/install/macos/mobile-android#configure-the-android-toolchain-in-android-studio)
* Have `VSCode` with `Flutter extension`
* Install latest `Flutter SDK` from the [docs](https://docs.flutter.dev/get-started/install/macos/mobile-ios#install-the-flutter-sdk)
* Make sure to export the Flutter `bin` target in your default terminal source of truth (e.g. `.zshenv`, `.zshrc`, ...), `export PATH=$HOME/your-path-to/flutter/bin:$PATH`


# Dart overview (models folder)


# Dev workflow (example app with the testing of the code)
TL;DR:

### iOS
Make sure to **build & run** the app from `Xcode` or run `flutter build ios --no-codesign --config-only` before developing the iOS layer code in Xcode for the first time.
Run `pod install` in the `example/ios` folder as all native code federation (and dedicated codegen) is the app's responsibility in Flutter.


### Android
Make sure to **build & run** the app from `Android Studio` or run `flutter build apk --config-only` before developing the native Android layer in AS for the first time.


For further dev, run `flutter run` with any running device / simulator. All platform-specific building will happen automagically. 
Hit `shift+R` for full reloads.

-------------------------------

The plugin is relatively linked to the example app, so no re-packing is required when developing.

All dependency invocation is a responsibility of the target app - e.g. our plugin does not contain a dedicated `Podfile` and `pod install` should be always run in the hosting app, as it also runs some codeged in it's `Runner` project for the automatic plugin registrar registration (sort of the autolinking of RN).
The **preferred & recommended** way to dev on the native code layer is through `Android Studio` and `Xcode`. 

The Android project is the `exmaple/android/` folder as per usual.
The Android code is linked in `example/android/app/src/main/kotlin/com/wultra/android/powerauth/flutter`.

The iOS project is `example/ios/Runner.xcworkspace`.
The iOS code is linked through the `.symlinks` folder, located in `Pods/Development Pods/hello/../../flutter_powerauth_mobile_sdk_plugin/ios/.symlinks/plugins/hello/ios/Classes`

## Dev app
The dev app (`example` - `flutter_powerauth_mobile_sdk_plugin_example`) app has currently implemented a single simple widget (a stateful widget - at least for now) for demonstration purposes.


## Testing
Tests are currently set up only as an exploration of the 
`package:flutter_test/flutter_test.dart`
`package:integration_test/integration_test.dart`
libs.

The `integration_test` library is actually quite powerful as it runs tests in a real app and on device, so all native code is actually available and there shoud technically be zero need for heavy mocks.

# Flutter Plugins & native (platform) code interop
All client (Flutter / Dart runtime) **<->** native communication in Flutter happens through `MethodChannels`. They are asynchronnous, named, and all the method calls are encoded to binary.

`Dart`:
```dart
final methodChannel = const MethodChannel('powerauth_plugin');
```

`Swift`:
```swift
let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
```

All plugins on the platform (native layer) side are registered into a `registar` (e.g. `FlutterPluginRegistry`). We only handle the plugin-side registration and method calls, the app registration happens automatically with codegen during config builds, and the `registrars` are injected into each auto-linked plugin.

## Plugin architecture 
Our SDK implemets a plugin technique called a `Federated Plugin`. It is an official Flutter abstraction for doing Plugin things.

__Traditionally, federated plugins have separately developed, versioned and released platform implementations for the plugin, as sometimes you want to outsource (e.g. **federate**) the platform dev to someone else, and then simply bring the dep. as a transient dependency (e.g. **endorse** a federated plugin). We do not need this as it brings an unnecessary layer of abstraction to our product case.__


# Platform abstractions


# Dart

# API additions