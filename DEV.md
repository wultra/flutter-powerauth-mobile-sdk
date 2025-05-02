# Flutter PowerAuth dev-ving

This is an internal Wultra-dev doc aimed at anyone interested in setting up a Flutter environment for the reading / contributing to the plugin SDK.

Links to full docs: [get started](https://docs.flutter.dev/get-started/learn-flutter) which contains some cool pointers such as [Flutter for SwiftUI Developers](https://docs.flutter.dev/get-started/flutter-for/swiftui-devs), [Flutter for React Native developers](https://docs.flutter.dev/get-started/flutter-for/react-native-devs).

# Flutter installation

Full docs [here](https://docs.flutter.dev/get-started/install/macos). Our SDK is targetting `Android` and `iOS` only.

! `flutter doctor` is an awesome tool to check, troubleshoot, and get recommended version upgrades for your setup.

* `Rosetta` is required for parts of Flutter. Run `sudo softwareupdate --install-rosetta --agree-to-license`
* Have `Xcode 16+`, `CocoaPods` set up with `v1.16+` (`sudo gem install cocoapods`) installed (or `Bundler` set up) 
* Have `Android Studio 2024.1 (Koala)+` with `Flutter plugin`, set up and install all Android-dev related stuff (SDK Platforms, cmd tools, build tools, emulator). There are no Flutter-specifics, so continue if you have the "standard" install. Full docs [here](https://docs.flutter.dev/get-started/install/macos/mobile-android#configure-the-android-toolchain-in-android-studio)
* Have `VSCode` with `Flutter extension`
* Install latest `Flutter SDK` from the [docs](https://docs.flutter.dev/get-started/install/macos/mobile-ios#install-the-flutter-sdk)
* Make sure to export the Flutter `bin` target in your default terminal source of truth (e.g. `.zshenv`, `.zshrc`, ...), `export PATH=$HOME/your-path-to/flutter/bin:$PATH`


# Dev workflow (example app with the testing of the code)
TL;DR:

### iOS
Make sure to run `flutter build ios --no-codesign --config-only` and/or **build & run** the app from `Xcode` before developing the iOS layer code in Xcode for the first time.
This is because of Flutter's codegen / linking / plugin init, etc.
Run `pod install` in the `example/ios` folder as all native code federation (and dedicated codegen) is the **app's responsibility** in Flutter.


### Android
Make sure to **build & run** the app from `Android Studio` or run `flutter build apk --config-only` before developing the native Android layer in AS for the first time.
This is because of Flutter's codegen / linking / plugin init, etc.

For further dev, run `flutter run` with any running device / simulator. All platform-specific building will happen automagically. 
Hit `shift+R` for full reloads.

-------------------------------

The plugin is relatively linked to the example app, so no re-packing is required when developing. If you change native layer code - you need to rebuild (fresh `flutter run` is enough).

All dependency invocation is a responsibility of the target app - e.g. our plugin does not contain a dedicated `Podfile` and `pod install` should be always run in the hosting app, as it also runs some codegen in it's `Runner` project for the automatic plugin registrar registration (sort of the autolinking of RN).
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

The `integration_test` library is actually quite powerful as it runs tests in a real app and on device, so all native code is actually available and there shoud technically be zero need for heavy mocks. Actual case of mocking is demonstrated in the `test/` folder of the SDK itself, but it was just an exploration how we could test the dry-run API calls.

# Flutter Plugins & native (platform) code interop
All client (Flutter / Dart runtime) **<->** native communication in Flutter happens through `MethodChannels`. They are asynchronnous, named, and all the method calls are **encoded to binary**. This is a major difference to RN's JSON everywhere (on the old arch).

`Dart`:
```dart
final methodChannel = const MethodChannel('powerauth_plugin');
```

`Swift`:
```swift
let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
```

All plugins on the platform (native layer) side are registered into a `registar` (e.g. `FlutterPluginRegistry`). We only handle the plugin-side registration and method calls, the app registration happens automatically with codegen during config builds, and the `registrars` are injected into the main discovered plugin.
The discovery is driven by the `pluginClass` and `package` fields for each platform in our `pubspec.yaml` definiton file.

! Please note that sub-plugins are **registered from the main plugin**. It is a standard way, tho we should test this a lot and might need to implement some sort of sub-moduling, similar to native layers in React Native, to be able to use all the plugins in the main `PowerAuth` one.

## Plugin environment
The plugin definition is driven purely by the `pubspec.yaml` file. `flutter pub add xxx` adds a dep. We version control all locks in both the app and in SDK.

Our plugin will once live on [pub.dev](https://pub.dev/). I will look into creating a company account there, so that we can publish the SDK under Wultra.
Interestingly, all plugins on pub.dev also have an auto-calculated [score mechanic](https://pub.dev/packages/datadog_flutter_plugin/score) based on pub.dev's static analysis of the plugin. We should strive to have as a high score as possible as a lower ones are kind of a smell in the Flutter community.

## Plugin architecture 
Our SDK implemets a plugin technique called a `Federated Plugin`. It is an official Flutter abstraction for doing Plugin things.

__Traditionally, federated plugins have separately developed, versioned and released platform implementations for the plugin, as sometimes you want to outsource (e.g. **federate**) the platform dev to someone else, and then simply bring the dep. as a transient dependency (e.g. **endorse** a federated plugin). We do not need this as it brings an unnecessary layer of abstraction to our product case.__

The currently implemented plugins are:
*   `powerauth`
*   `powerauth_password`
*   `powerauth_utils` (somewhat, they live on `powerauth`'s method channel - need to TODO this)

Each plugin typically contains:
1.  A `_platform_interface.dart` file.
2.  A `_method_channel.dart` file.
3.  A client-facing API class (e.g., `PowerAuth.dart`, `PowerAuth.dart`).

# Platform abstractions
We utilize the `plugin_platform_interface` package to define clear contracts between the Dart API and the underlying native implementations. In the future, I also want to explore the `Pigeon` package which codegens the strictly typed native interfaces straight from Dart definitions.

1.  **Platform Interface (`_platform_interface.dart`):**
    *   Each plugin (e.g., `powerauth`) has an abstract class extending `PlatformInterface` (e.g., `PowerAuthPlatform`).
    *   This class defines the set of the API methods that any platform implementation has to implement.
    *   Method bodies in the platform interface simply `throw UnimplementedError(...)`. This is a standard practice, however we can move from it and have simply `no-body` declarations.

    ```dart
    abstract class PowerAuthPlatform extends PlatformInterface {
      ...
      Future<bool> hasValidActivation(String instanceId) {
        throw UnimplementedError('hasValidActivation() has not been implemented.');
      }
    }
    ```
    *   It holds its `static instance` that points to the currently active platform implementation (defaulting to the MethodChannel version).

2.  **Method Channel Implementation (`_method_channel.dart`):**
    *   Each plugin has a concrete class extending its platform interface (e.g., `PowerAuthMethodChannel extends PowerAuthPlatform`).
    *   This class provides the actual implementation of communicating with the native code over a shared `MethodChannel` (named `'powerauth_plugin'`).
    *   It uses a common `MethodChannelHelper` mixin (`lib/src/utils/method_channel_helper.dart`) to standardize method invocation (`invokeMethod`, `invokeNullableMethod`) and error handling (converting `PlatformException` to `PowerAuthException`), etc. We might revisit what parts get wrapped and how we handle the actual exceptions.

    ```dart
    class PowerAuthMethodChannel extends PowerAuthPlatform with MethodChannelHelper {
      @override
      final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

      @override
      Future<bool> hasValidActivation(String instanceId) async {
        return await invokeMethod<bool>('hasValidActivation', {'instanceId': instanceId});
      }
    }
    ```

# API additions
The primary entry points for developers are classes like `PowerAuth`, `PowerAuthPassword`, ...
They **delegate** all calls to the appropriate platform interface instance.

    ```dart
    class PowerAuth {
      final String instanceId;
      static PowerAuthPlatform get _platform => PowerAuthPlatform.instance;

      PowerAuthCore(this.instanceId) { /* ... */ }

      Future<bool> hasValidActivation() => _platform.hasValidActivation(instanceId);
    }
    ```

# Dart
Lang docs [here](https://dart.dev/overview).
Dart is a truly strictly typed language. This makes the work awesome! And sad, compared to TS.
The main sadness is the missing of the wide type allowances like union types, some actual nice features coming from object structure duck types, etc...
Lack of union types is best shown in the passing of `PowerAuthPassword` around. We currently simply shop it with `Object` type and only perform a runtime check whether its a `String` or the `PowerAuthPassword`. This is a bit sad, but its a kinda standard practise; ofc we can go with implementing a wrapper that would check this earlier, but I don't know whether its something we really need right now.

On the other hand we already use some interesting (and *weird*) Dart features and design choices:

### `factory` constructors:
Smells like Java but its not Java!

Factories are special cases of constructors in Dart, which can be used for cases like subtype instantiation, but more importantly as `named constructors`.
This means that we can use these special constructors for, for example, the construction of our concrete model types out from the `Map<dynamic,dynamic>` data we get from a lot of native layer method calls.

We would technically achieve something similar with `static methods` (just as they're mostly implemented in RN / TS), but these named constructors are super idiomatic to Dart and relieve us from the need to call internal constructors, etc...

### `positional` vs `named` parameters in functions:
Consider following function declarations:

```dart
void logEvent([Map<String, Object?> attributes = const {}])
```

```dart
void logEvent({Map<String, Object?> attributes = const {}})
```

Do you think that `[]` wrapping means this is part of a variable array declaration?
Do you think that `{}` wrapping means this is part of an anonymous object construction?
No HAHA!

`[]` is an optional positional argument. That means:
* The parameter can be omitted when the function is called.
* If omitted, it will use the default value provided (if any).
This means that attributes will be any an **empty const object** if not passed.

`{}` is (an optional) named argument - e.g. `logEvent(attributes: {'time': 420});`

I mean what can we do...