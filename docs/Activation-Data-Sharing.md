# Share Activation Data

This chapter explains how to share the PowerAuth activation state between an iOS application and its extensions, or between multiple iOS applications from the same vendor.

<!-- begin box info -->
This feature is available only on iOS. `PowerAuthSharingConfiguration` is ignored on Android, where `sharingConfiguration` and `getExternalPendingOperation()` return `null`.
<!-- end -->

<!-- begin box warning -->
If you already use activation data sharing with an SDK older than 2.0.0, read [Upgrade from Older SDKs](#upgrade-from-older-sdks) before changing the configured algorithm.
<!-- end -->

## Prepare Activation Data Sharing

An application extension cannot normally access data created by its containing application. Before configuring PowerAuth, enable both Keychain Sharing and App Groups for every participating target.

### Keychain Sharing

PowerAuth stores its most sensitive data in the iOS keychain. To make the same activation available to multiple applications or extensions, configure one shared keychain access group:

1. Select the application project in Xcode and choose the application's target under **TARGETS**.
2. Open **Signing & Capabilities**, click **+ Capability**, and add **Keychain Sharing**.
3. Add the keychain group you want to share. Xcode typically suggests the application's bundle identifier. In this guide, this value is called `KEYCHAIN_GROUP_NAME`.
4. Repeat these steps for every participating application and extension, adding the same `KEYCHAIN_GROUP_NAME` to each target.
5. Find the Apple **Team ID** associated with the signing team.
6. Build the fully qualified keychain access-group identifier as `TEAM_ID.KEYCHAIN_GROUP_NAME`. For example: `KTT00000MR.com.powerauth.demo.App`.

<!-- begin box info -->
If an existing application already stores PowerAuth data in the keychain, using its predefined keychain group is usually the simplest way to add extension support.
<!-- end -->

The final `KEYCHAIN_GROUP_IDENTIFIER` must be present in the signed entitlements and provisioning profiles of every participating target. Supplying it only in Dart configuration is not sufficient.

### App Groups

PowerAuth uses a flag in `UserDefaults` to detect application reinstallation. Standard user defaults are not shared with extensions, so all participating targets must also use one App Group.

1. Select the application's target in Xcode.
2. Open **Signing & Capabilities**, click **+ Capability**, and add **App Groups**.
3. Add or enable the App Group you want to share. In this guide, this value is called `APP_GROUP_IDENTIFIER`.
4. Repeat these steps for every participating application and extension, enabling the same `APP_GROUP_IDENTIFIER` in each target.

The App Group must be present in the signed entitlements and provisioning profiles of every participating target.

If an existing application did not previously share activation data, you may also need to [migrate the UserDefaults initialization flag](#userdefaults-migration).

For more details about configuring the Apple targets, see [Share Activation Data](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#share-activation-data) in the native iOS SDK documentation.

## Configure Activation Data Sharing

Create a `PowerAuthSharingConfiguration` and pass it to `configure()`:

```dart
// Keychain Sharing and App Group constants.
const keychainSharing =
    "KTT00000MR.com.powerauth.demo.App"; // KEYCHAIN_GROUP_IDENTIFIER
const appGroup = "group.your.app.group"; // APP_GROUP_IDENTIFIER

final configuration = PowerAuthConfiguration(
    configuration: "ARDDj6EB6iAUtNm...KKEcBxbnH9bMk8Ju3K1wmjbA==",
    baseEndpointUrl: "https://<your-domain>/enrollment-server",
);

// Do not derive this value separately from each target's bundle identifier.
const sharedPowerAuthInstanceId = "com.powerauth.demo.shared-instance";

final sharingConfiguration = PowerAuthSharingConfiguration(
    appGroup: appGroup,
    appIdentifier: "com.powerauth.demo.App",
    keychainAccessGroup: keychainSharing,
);

final powerAuth = PowerAuth(sharedPowerAuthInstanceId);
await powerAuth.configure(
    configuration: configuration,
    sharingConfiguration: sharingConfiguration,
);
```

The `PowerAuthSharingConfiguration` object contains the following properties:

- `appGroup` is the App Group shared by all participating applications and extensions. It must not be empty. With the default shared-memory identifier, its UTF-8 representation must not exceed 26 bytes. See [Length of Application Group](#length-of-application-group) for details.
- `appIdentifier` identifies the application or extension that currently holds the lock for an exclusive operation. It must be unique across all participants, must not be empty, and must not exceed 127 UTF-8 bytes. An application's bundle identifier is usually a good value.
- `keychainAccessGroup` is the fully qualified access group configured in Keychain Sharing. All participants must use the same value.
- `sharedMemoryIdentifier` optionally overrides the short identifier used for cross-process coordination. Normally, omit it and let the SDK generate a four-character identifier from the shared `PowerAuth.instanceId`. If you override it, all participants must use the same value.

<!-- begin box info -->
All applications and extensions sharing one activation must construct `PowerAuth` with the same `instanceId`. Do not derive the value independently from each target's bundle identifier. Use a predefined constant or an identifier based on the first application that integrated PowerAuth.
<!-- end -->

<!-- begin box warning -->
Do not reuse one `appIdentifier` for multiple `PowerAuth` instances running in the same application or extension.
<!-- end -->

Every participant must also use the same PowerAuth application configuration data and connect to the same compatible PowerAuth Server environment.

After configuration, the asynchronous `sharingConfiguration` getter returns the effective native configuration. If the input omitted `sharedMemoryIdentifier`, the returned configuration contains the generated identifier.

## External Pending Operations

Some operations, including activation creation and protocol upgrade, must be completed exclusively by the application that started them. Other applications sharing the activation may receive `PowerAuthErrorCode.externalPendingOperation` until the operation finishes.

You can check for such an operation in advance:

```dart
final externalOperation = await powerAuth.getExternalPendingOperation();
if (externalOperation != null) {
    print(
        "Application ${externalOperation.externalApplicationId} already "
        "started ${externalOperation.externalOperationType.name}",
    );
    return;
}
```

The operation type is either:

- `PowerAuthExternalPendingOperationType.activation`
- `PowerAuthExternalPendingOperationType.protocolUpgrade`

The state can change after the check. Handle `PowerAuthErrorCode.externalPendingOperation` when starting either operation, then call `getExternalPendingOperation()` again to identify the other application.

## Troubleshooting

### Length of Application Group

Activation data sharing uses a named shared-memory object, whose name is limited to 31 UTF-8 bytes. The name contains the App Group, a period, and a short shared-memory identifier.

By default, PowerAuth generates a four-character identifier from `PowerAuth.instanceId`, leaving 26 bytes for the App Group:

```text
31 - 1 - 4 = 26
```

You can slightly extend the available App Group length by explicitly setting a shorter `sharedMemoryIdentifier`. With a one-character identifier, the App Group can contain up to 29 UTF-8 bytes.

An explicit `sharedMemoryIdentifier` must contain 1 to 4 UTF-8 bytes and may contain only ASCII letters, digits, `+`, and `-`. A custom identifier is generally unnecessary. Use one only when the generated name conflicts with another shared-memory object or when a longer App Group name is unavoidable. Every participant must use the same effective identifier.

### UserDefaults Migration

If a previous application version did not share activation data, or if the App Group changes, migrate the keychain initialization flag at application startup, **before** configuring or using any `PowerAuth` instance:

```dart
await PowerAuthUtils.migrateiOSSharingConfiguration(
    from: previousSharingConfiguration,
    to: newSharingConfiguration,
);
```

Use this operation only after consulting Wultra support or engineering. Incorrect migration can make existing activation data unavailable. The `from` and `to` configurations are nullable so the operation can represent enabling or disabling sharing. See [Additional Utilities](Additional-Utilities.md#migrateiossharingconfiguration) for validation rules.

### Upgrade from Older SDKs

PowerAuth Mobile SDK 2.0 introduced a new internal activation-data format. If several independently distributed applications share one activation, an updated application can write data that an application using SDK 1.x cannot recognize.

Use the following staged rollout:

1. Update all participating applications to SDK 2.0 or later and configure `PowerAuthAlgorithm.legacy`.
2. Wait until a sufficient number of users have installed the updated versions of all participating applications.
3. Switch to the selected protocol 4.0 algorithm.

<!-- begin box info -->
This staged procedure is not required when sharing occurs only between one application and its bundled extensions, because they are updated together.
<!-- end -->

See [Migration from 1.4.x to 2.0.x](Migration-from-1.4-to-2.0.md#activation-data-sharing) for the complete SDK migration guide.

## Read Next

- [Configuration](Configuration.md)
- [Error Handling](Error-Handling.md)
