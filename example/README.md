# PowerAuth Flutter SDK Example

This application provides a small configuration example, interactive PowerAuth SDK tests, and the integration-test suite used by this repository.

## Prerequisites

- Flutter and Dart versions supported by the parent package
- Java 17 and an Android device or emulator for Android
- Xcode and an iOS device or simulator for iOS
- A PowerAuth application and server environment

See the main [installation](../docs/Installation.md) and [configuration](../docs/Configuration.md) guides for the platform requirements and SDK configuration procedure.

## Configure the Example

The application declares `.env` as a Flutter asset. Create this file before fetching dependencies or building the application:

```bash
cd example
cp .env-example .env
```

Fill the required values in `.env`:

| Variable | Purpose |
|---|---|
| `ENROLLMENT_URL` | Base URL of the PowerAuth Enrollment Server used by the mobile SDK. |
| `SDK_CONFIG` | Mobile SDK configuration string for the PowerAuth application. |
| `CLOUD_URL` | Base URL of the PowerAuth Cloud API used by interactive and integration tests. |
| `CLOUD_LOGIN` | PowerAuth Cloud API username. |
| `CLOUD_PASSWORD` | PowerAuth Cloud API password. |
| `CLOUD_APPLICATION_ID` | Identifier of the PowerAuth application used by the tests. |
| `UDS_SERVER_URL` | User Data Store URL used by user-info tests. |
| `UDS_SERVER_USERNAME` | User Data Store username. |
| `UDS_SERVER_PASSWORD` | User Data Store password. |

The **Simple Configuration** screen needs only `ENROLLMENT_URL` and `SDK_CONFIG`. The interactive test screen and the full integration suite also create, commit, and remove server-side activations, so they require the PowerAuth Cloud values. User-info integration tests additionally require the User Data Store values.

The `.env` file is excluded from Git. Do not commit credentials or include them in application logs.

## Run the Application

From the `example` directory, run:

```bash
flutter pub get
flutter run
```

Select the target device with `flutter devices` and `flutter run -d <device-id>` when more than one device is available. Biometric behavior is best verified on a physical device with enrolled biometrics.

## Run Integration Tests

The integration suite changes server state by creating and removing test activations. Use a dedicated non-production PowerAuth application.

On an Android device or emulator, run from the `example` directory:

```bash
flutter test -r expanded integration_test/plugin_integration_test.dart --timeout 5m
```

On macOS, the repository provides an iOS simulator runner. Run it from the repository root:

```bash
bash scripts/integration-tests-ios.sh
```

The iOS script selects an available iPhone simulator and enables Flutter Swift Package Manager integration before running the tests.
