# Troubleshooting

<!-- ## Upgrading SDK

If you upgraded SDK to a newer major or minor version and encounter some problems, then please follow the [Migration Instructions](Migration-Instructions.md) first. -->

## Enable debug log

In case you encounter a problem with this library, then try to turn-on a detailed debug log to provide a more information for the library developers:

```dart
// Enable debug log with failed call to native function.
PowerAuthDebug.traceNativeCodeCalls(traceFailure: true);
// Trace all calls to native library
PowerAuthDebug.traceNativeCodeCalls(traceEachCall: true, traceFailure: true);
```

<!-- begin box warning -->
The `PowerAuthDebug` class is effective only when `isEnabled` is `true`, which is only when the app is compiled in debug mode (`kDebugMode` is `true`). We don't want to log sensitive information to the console in the production application.
<!-- end -->

## Dumping native objects

If `PowerAuthDebug.isEnabled` is turned on, then you can dump information about all native objects allocated and used by PowerAuth Mobile Flutter SDK:

```dart
// Dump all objects
await PowerAuthDebug.dumpNativeObjects();
// Dump objects related to PowerAuth instance
await PowerAuthDebug.dumpNativeObjects(instanceId: powerAuth.instanceId);
```

## Read Next

- [User Info](User-Info.md)