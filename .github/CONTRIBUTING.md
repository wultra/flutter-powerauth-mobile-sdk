# Welcome to the Flutter PowerAuth Mobile SDK repository!

In this file, you'll find several topics that will help get up-to-speed with development, how to properly contribute, how to run tests, how to create pull requests and how to prepare a new release.

## Table of Contents
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Tests](#tests)
- [Creating a Pull Request](#creating-a-pull-request)
- [Preparing a New Release](#preparing-a-new-release)

# Getting Started

> [!WARNING]
> If you're not a Wultra employee or contractor, please fill out the [Wultra Contributor License Agreement](https://forms.gle/r715RoVDoji4GD7K7) before you start contributing.

> [!NOTE]
> We recommend development on the macOS platform, as the iOS simulator is only available on macOS. However, you can also develop on Windows or Linux, but you will need a Mac to build and test the iOS version of the SDK.

> [!NOTE]
> Our recommended IDE for development is [Visual Studio Code](https://code.visualstudio.com/) with [Flutter Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) installed.
>
> You can use other IDEs that are capable of Flutter development, but we recommend using Visual Studio Code for its simplicity and ease of use.

Before you start development, make sure you have the following prerequisites:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
- [Android Studio](https://developer.android.com/studio) installed for Android development.
- [Xcode](https://developer.apple.com/xcode/) (for iOS development) installed on your Mac.
- [CocoaPods](https://guides.cocoapods.org/using/getting-started.html) installed for iOS development.
- Flutter-capable IDE installed (Visual Studio Code with Flutter Extension is recommended).

# Project Structure

The project structure is organized as follows (the most important files and directories):

```
flutter-powerauth-mobile-sdk/
├── .github/                 # GitHub-related files (workflows, contributing guidelines)
├── android/                 # Android native code (bridge between Flutter and native PowerAuth SDK)
├── docs/                    # Documentation files that will be published on developers.wultra.com
├── example/                 # Example app showcasing the SDK and hosting integration tests
│   ├── .env                 # Environment variables for the integration tests
│   ├── .env-example         # Example environment variables for the integration tests
│   ├── integration_test/    # Integration tests for the SDK
│   └── lib/                 # Source code of the example application + biometrics tests
├── ios/                     # iOS native code (bridge between Flutter and native PowerAuth SDK)
├── lib/                     # Main library code
│   ├── src/                 # Source code of the SDK
│   └── flutter_powerauth_mobile_sdk_plugin.dart  # Public API of the SDK
├── scripts/                 # Scripts for building, testing, releasing
├── test/                    # Unit tests for the SDK
├── .prepare-release.json    # Definition file for the release (that runs in CI pipeline)
├── CHANGELOG.md             # Changelog of the SDK that is visible on pub.dev
├── pubspec.yaml             # Project metadata and dependencies
└── README.md                # Project overview and documentation
```

# Architecture Overview

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

The currently implemented plugins are for example:
*   `powerauth`
*   `powerauth_password`
*   `powerauth_utils`

Each plugin typically contains:
1.  A `_platform_interface.dart` file.
2.  A `_method_channel.dart` file.
3.  A client-facing API class (e.g., `PowerAuth.dart`, `PowerAuth.dart`).

## Platform abstractions

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

## API additions
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

# Tests

Before you run the tests, make sure:
- the `example/.env` file is set up correctly. You can use the `.env-example` file as a reference.
  - variables needed can be provided by the Wultra team or your own development team in case of self-hosted environments
- dependencies in the `example` directory are installed by running `flutter pub get`.
- CocoaPods dependencies are installed for iOS by running `pod install` in the `example/ios` directory.

### Unit Tests

To run the unit tests, use the following command:

```bash
flutter test
```

## Integration Tests

Integration test are located in the `example/integration_test` directory.

> [!NOTE]
> To run the test on desired device, we recommend using the UI of the flutter extension in Visual Studio Code.
>
> When integration tests are run from the command line, the first available device is used. If you want to run the tests on a specific device, you can use the `-d` option with the device ID.

To run the integration tests, use the following command:

```bash
cd example # make sure you are in the example directory
flutter test -r expanded integration_test/integration_test.dart # test with expanded report
```

# Creating a Pull Request

> [!WARNING]
> Before you create a pull request make sure that: 
> 
> - an issue is created for the change you want to make. If there is no issue, create one first.
> - all unit tests and integration tests are passing.
> - `flutter analyze` does not report any issues.

0. If you're not a Wultra employee or contractor, fork the repository and make changes in your fork. If you're a Wultra employee or contractor, you can make changes directly in the repository.
1. Create a new branch for your changes. The branch name should follow the format `issues/issue-number-short-description`, e.g. `issues/123-fix-bug-in-inbox`.
2. Make your changes and commit them with a clear commit message that describes the changes you made.
3. Push your changes to the remote repository.
4. Create a pull request from your branch to the `develop` branch of the repository.
    - Pick a descriptive title for your pull request that summarizes the changes you made.
    -  In the pull request description, reference the issue you are addressing by using `#issue-number`, e.g. `#123`. This will automatically link the pull request to the issue.
    - If you're not a Wultra employee or contractor, wait for a Wultra team member to review your pull request and approve workflows to run.
    - If you're a Wultra employee or contractor, wait for all workflows to pass and then request review from a Wultra maintainer.

# Preparing a New Release

> [!WARNING]
> This section is intended for Wultra employees and contractors only. If you are not a Wultra employee or contractor, please do not attempt to prepare a new release.

## Some important notes regarding the release streams (branches)

- the `develop` branch is used for development and should not be used for releases
- each release stream should be created from the `develop` branch (can be specific commit in the history)
- naming of the release stream should follow the format `release/a.b.x`, e.g. `release/1.0.x`
- git history of the release stream should be always linear, i.e. no merge commits should be present in the history
- every change into the release stream should be done via a pull request that will be squashed and merged into the release stream

## Release Versioning

The version number is composed of three parts: `major.minor.patch`, e.g. `1.0.0`.

- The `major` version is incremented when a milestone is reached, e.g. a platform version is updated or major principle is changed.
- The `minor` version is incremented when a new feature is added or a significant change is made. Minor changes can be API incompatible, but they should not break existing functionality.
- The `patch` version is incremented when a bug fix is introduced. No API changes are allowed in patch releases, and they should not break existing functionality or introduce new features.

## Each release should contain following changes

> [!TIP]
> You can use the `scripts/prepare-release.sh` script to prepare all the necessary files for a new release.
> 
> If you pass a `--verify` flag to the script, it will check if all the files are updated correctly and will not allow you to proceed with the release if any of the files are not updated.

- updated `pubspec.yaml` file with the new version number
- updated `lib/src/version.dart` file with the new version number
- updated `CHANGELOG.md` file with the new version number and a summary of the changes for pub.dev
- updated `docs/changelog.md` file with the new version number and a summary of the changes for Wultra developers documentation
- updated `docs/Installation.md` file with the new version in example of how to add the dependency
- _(if needed)_ updated `docs/PowerAuth-Server-Compatibility.md` file with the new version and compatibility information

## Creating a Release (example scenario)

> [!NOTE]
> This scenario describes how to create a new `1.2.0` release of the SDK from the HEAD of the `develop` branch.

1. Create an issue for the new release, e.g. `Prepare release 1.2.0`. Add info what is the reason for the release.
2. Prepare new branch from `develop` branch without any changes (if a release branch does not exist yet) and push it to the remote repository without any changes. Release branches are protected and can be created only by Wultra employees or contractors:
    - `git checkout develop`
    - `git pull origin develop`
    - `git checkout -b release/1.2.x`
    - `git push -u origin release/1.2.x`
3. Create a new branch for the exact release (for example `issues/65-prepare-release-1_2_0`).
4. Make sure that all the files mentioned in the "[each release should contain following changes](#each-release-should-contain-following-changes)" section are updated correctly.
5. Commit the changes with a clear commit message, e.g. `Prepare release 1.2.0`.
6. Push the changes to the remote repository.
7. Create a pull request from the `issues/65-prepare-release-1_2_0` branch to the `release/1.2.x` branch.
    - The pull request title should be `Prepare release 1.2.0`.
    - The pull request description should reference the issue you created in the first step, e.g. `#65`.
8. Wait for the pull request to be reviewed and approved by a Wultra team member.
9. Once the pull request is approved, merge it into the `release/1.2.x` branch using the "Squash and merge" option. This will ensure that the git history is linear, and the commit message is clear.
10. Go to the [Wultra Azure DevOps portal](https://dev.azure.com/wultra) and run the `flutter-powerauth-mobile-sdk` release pipeline. In the pipeline
    - specify the `release/1.2.x` branch as the source branch
    - specify the `1.2.0` version as the release version
    - the pipeline will verify that all the files are updated correctly and that the git history is linear
    - the pipeline will automatically create a new tag `1.2.0` in the repository
    - the pipeline will also automatically publish the new version to pub.dev
11. Create a new release on GitHub:
    - Go to the "Releases" section of the repository.
    - Click on "Draft a new release".
    - Select the `1.2.0` tag you just created.
    - Fill in the release title and description. The description should contain a summary of the changes made in the release, which can be copied from the `CHANGELOG.md` file.
12. Verify that the release is published on pub.dev
