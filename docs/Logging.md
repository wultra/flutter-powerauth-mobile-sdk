# Logging

The PowerAuth Mobile SDK provides a comprehensive logging system that captures information from all layers of the stack, including the Dart plugin, the native Android/iOS wrappers, and the underlying native PowerAuth SDKs.

## 1. Listening to Logs

The primary way to interact with the logging system is by listening to the log stream. All log entries, regardless of their origin, are broadcast through this stream. The stream is exposed via the `PowerAuthDebug` class.
Accessing the stream is only possible in **debug** builds.

Listening to the `PowerAuthDebug.logStream` for the first time will automatically initialize the native log listeners with default configuration, ensuring that no logs are lost.

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

By default, logging is **enabled** in debug builds and **disabled** in release builds. You can override this at any time.

**Parameters:**
- `config`: A `PowerAuthLoggingConfig` object that contains all logging settings.

The `PowerAuthLoggingConfig` class has the following properties:
- `enabled`: A `bool` to turn logging on or off (defaults to `kDebugMode`).
- `level`: A `PowerAuthLogLevel` enum value that sets the minimum level of logs to be processed (defaults to `.info`).
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
    // In production, you might want to only log critical errors.
    await PowerAuthDebug.configureLogging(
      const PowerAuthLoggingConfig(
        enabled: true,
        level: PowerAuthLogLevel.error,
        logToConsole: false,
      ),
    );
  }
}
```

**Using the default configuration:**
```dart
// Use all defaults (enabled in debug mode, info level, console logging on)
await PowerAuthDebug.configureLogging(const PowerAuthLoggingConfig());
```

## Read Next

- [Troubleshooting](./Troubleshooting.md)