# Activation Data Sharing

Activation data sharing allows multiple iOS applications or extensions from the same developer to use one PowerAuth activation. This feature is available only on iOS. The related configuration is ignored on Android, and `getExternalPendingOperation()` returns `null` there.

<!-- begin box warning -->
Upgrading an existing shared activation from SDK 1.x requires a staged rollout. See [Migration from 1.4.x to 2.0.x](Migration-from-1.4-to-2.0.md#activation-data-sharing) before changing the algorithm.
<!-- end -->

Sharing activation data requires both an Apple project configuration and a matching `PowerAuthSharingConfiguration`. Configure every participating target before creating the shared activation.

## Prepare Apple Targets

For every application and extension that participates in sharing:

1. Add the **Keychain Sharing** capability.
2. Add the same keychain access group to every target.
3. Add the **App Groups** capability.
4. Enable the same app group for every target.

The application signing profiles must contain these entitlements. A value present only in Dart configuration is not sufficient.

For the detailed Xcode procedure, see [Share Activation Data](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#share-activation-data) in the native iOS documentation.

## Configure Sharing

All participating applications and extensions must use:

- The same `PowerAuth.instanceId`. Do not derive this value independently from each target's bundle identifier.
- The same `appGroup`, configured in every target's App Groups entitlement.
- The same `keychainAccessGroup`, configured in every target's Keychain Sharing entitlement.
- The same effective `sharedMemoryIdentifier`. Omit it in every target to derive it from the shared `PowerAuth.instanceId`; if you override it, use the same explicit value in every target.
- A different `appIdentifier` for each participating application or extension.

These sharing identifiers do not replace the main SDK configuration. Every participant must use the same PowerAuth application cryptographic configuration and connect to a compatible PowerAuth Server environment.

```dart
const sharedPowerAuthInstanceId = "com.example.shared-powerauth";

final sharingConfiguration = PowerAuthSharingConfiguration(
    appGroup: "group.com.example.powerauth",
    appIdentifier: "com.example.main-app",
    keychainAccessGroup: "TEAM_ID.com.example.powerauth",
);

final powerAuth = PowerAuth(sharedPowerAuthInstanceId);
await powerAuth.configure(
    configuration: configuration,
    sharingConfiguration: sharingConfiguration,
);
```

Use a different `appIdentifier`, such as `com.example.widget-extension`, in another target. Do not use one `appIdentifier` for multiple `PowerAuth` instances running in the same process.

Normally, omit `sharedMemoryIdentifier` and let the SDK derive it. Set a custom value only if the generated shared-memory name conflicts with another object or if you need to accommodate a longer app-group name. When you provide one, every participating target must use the same value.

The native SDK applies the following size limits:

- With the default derived shared-memory identifier, the UTF-8 representation of `appGroup` must not exceed 26 bytes.
- The UTF-8 representation of `appIdentifier` must not exceed 127 bytes.
- An explicit `sharedMemoryIdentifier` must contain 1 to 4 UTF-8 bytes and may contain only ASCII letters, digits, `+`, and `-`.

A shorter custom `sharedMemoryIdentifier` can accommodate a slightly longer app-group name. With a one-byte identifier, the app-group name can contain up to 29 UTF-8 bytes.

## External Pending Operations

Activation creation and protocol upgrade are exclusive operations. An application that shares activation data cannot start the same sensitive operation while another application is performing it.

Check the state before starting such an operation:

```dart
final externalOperation = await powerAuth.getExternalPendingOperation();
if (externalOperation != null) {
    print(
        "${externalOperation.externalApplicationId} is performing "
        "${externalOperation.externalOperationType.name}",
    );
    return;
}
```

The operation type is either:

- `PowerAuthExternalPendingOperationType.activation`
- `PowerAuthExternalPendingOperationType.protocolUpgrade`

A race is still possible after the check. Handle `PowerAuthErrorCode.externalPendingOperation` when starting activation or protocol upgrade, then query `getExternalPendingOperation()` again to identify the other application.

## Changing an Existing Sharing Configuration

The iOS SDK stores a flag used to recognize application reinstallation. When sharing is enabled, disabled, or moved to another app group, migrate this flag before configuring any `PowerAuth` instance:

```dart
await PowerAuthUtils.migrateiOSSharingConfiguration(
    from: previousSharingConfiguration,
    to: newSharingConfiguration,
);
```

Use this operation only after consulting Wultra support or engineering. An incorrect migration can make existing activation data unavailable. See [Additional Utilities](Additional-Utilities.md#migrateiossharingconfiguration) for parameter validation and nullable configurations.

## Read Next

- [Configuration](Configuration.md)
- [Error Handling](Error-Handling.md)
