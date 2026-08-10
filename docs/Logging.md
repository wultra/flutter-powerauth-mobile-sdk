# Logging

The PowerAuth Mobile SDK provides a comprehensive logging system that captures information from all layers of the stack, including the Dart plugin, the native Android/iOS wrappers, and the underlying native PowerAuth SDKs.

## 1. Listening to Logs

The primary way to interact with the logging system is by listening to the log stream exposed by the `PowerAuthDebug` class. Native wrapper and native SDK entries are sent to the stream regardless of the configured level. Entries produced by the Dart plugin are filtered by the configured level before they reach the stream.

Listening to `PowerAuthDebug.logStream` for the first time initializes the native log listener. Log events produced before the first listener is attached are not buffered.

Logging may contain operational or sensitive diagnostic data. Keep it disabled in production applications.

**Example:**
```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

void listenToPowerAuthLogs() {
  // Listening to the stream automatically handles initialization.
  PowerAuthDebug.logStream.listen((log) {
    // We recommend using a dedicated logging library to process logs.
    // For this example, we will just print to the console.
    final tag = log.tag != null ? "[${log.tag}]" : "";
    final timestamp = log.timestamp.toIso8601String();
    print("PowerAuthSDK ${log.level.name.toUpperCase()}$tag [$timestamp]: ${log.message}");
  });
}
```

The `PowerAuthLog` object received by the stream contains the following properties:
- `level`: A `PowerAuthLogLevel` enum (`verbose`, `debug`, `info`, `warning`, `error`).
- `message`: The `String` content of the log.
- `tag`: An optional `String` tag. Logs originating from the native PowerAuth SDKs will have the `PowerAuthNativeSDK` tag.
- `timestamp`: A `DateTime` indicating when the log entry was created.

## 2. Configuring the Logger

You can control the behavior of the logger through the `PowerAuthDebug.configureLogging()` method. This is typically done once when your application starts. Calling this method will also automatically initialize the native log listeners.

The default Dart configuration enables logging in debug builds and disables it in release builds by using `kDebugMode`. This Dart default is not applied automatically to the native wrappers. Native wrapper logging and console output remain enabled until `configureLogging()` is called. Call this method once during application startup to apply the same effective configuration to Dart, Android, and iOS, especially when disabling logging in a release build.

**Parameters:**
- `config`: A `PowerAuthLoggingConfig` object that contains all logging settings.

The `PowerAuthLoggingConfig` class has the following properties:
- `enabled`: A `bool` to turn logging on or off (defaults to `kDebugMode`). The value is applied to the native wrappers only after `configureLogging()` is called.
- `level`: A `PowerAuthLogLevel` enum value that sets the minimum processed level (defaults to `.info`). It filters Dart-originated stream entries and console output. Native wrapper and native SDK entries below this level are still sent to the stream.
- `logToConsole`: A `bool` that controls whether logs are also printed to the platform console (defaults to `true`).

**Example:**
```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter/foundation.dart';

Future<void> setupMyApplication() async {
  if (kDebugMode) {
    await PowerAuthDebug.configureLogging(
      const PowerAuthLoggingConfig(
        enabled: true,
        level: PowerAuthLogLevel.verbose,
        logToConsole: true,
      ),
    );
  } else {
    // Do not collect PowerAuth diagnostics in production.
    await PowerAuthDebug.configureLogging(
      const PowerAuthLoggingConfig(
        enabled: false,
        level: PowerAuthLogLevel.error,
        logToConsole: false,
      ),
    );
  }
}
```

**Using the default configuration:**
```dart
// Apply the Dart defaults to all layers: enabled in debug mode,
// disabled in release mode, info level, console logging on when enabled.
await PowerAuthDebug.configureLogging(const PowerAuthLoggingConfig());
```

## Read Next

- [Time Synchronization](Time-Synchronization.md)
