# Configuration

Before you call any method on the newly created `final powerAuth = PowerAuth(instanceId);` object, you need to configure it first. An unconfigured instance will throw exceptions. Use `await powerAuth.isConfigured();` to check if configured.

## 1. Parameters

You will need the following parameters to prepare and configure a PowerAuth instance:

- **instanceId** - Identifier of the app - the application package name/identifier is recommended.
- **configuration** - String (base64) with the cryptographic configuration - this configuration can be retrieved via the `Get App Details` Admin API in the PowerAuth Cloud server component.
- **baseEndpointUrl** - Base URL to the PowerAuth Standard RESTful API. _(usually something like `https://<your-domain>/enrollment-server`)_

## 2. Configuration

### Basic configuration

To configure the PowerAuth instance, simply import it from the plugin and use the following snippet.

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

Future<void> initPowerauth() async {
    final powerAuth = PowerAuth("your-app-instance-id");
    
    // An already configured instance will throw an
    // exception when you try to configure it again
    if (await powerAuth.isConfigured()) {
        print("PowerAuth was already configured.");
    } else {
        try {
            final configuration = PowerAuthConfiguration(
                configuration: "ARCB+/qxp........IQ5E5jg==",
                baseEndpointUrl: "https://<your-domain>/enrollment-server",
            );
            await powerAuth.configure(configuration: configuration);
            
            // powerAuth object configured
              
        } on PowerAuthException catch (configError) {
            print("PowerAuth configuration failed (Code: ${configError.code}, msg: ${configError.message}). ");
        } catch (configError) {
            print("Failed to auto-configure PowerAuth (Unknown Error): $configError");
        }
    }
}
```

> Note: SDK configuration is kept in native state, so it survives Flutter hot restart and hot reload.

### Algorithms for Communication

PowerAuth Mobile SDK supports the following algorithms:

- `PowerAuthAlgorithm.p384l3` uses a hybrid scheme with P-384, ML-KEM-768, and ML-DSA-65. This is the default algorithm and provides the best balance between performance and post-quantum security.
- `PowerAuthAlgorithm.p384l5` uses a hybrid scheme with P-384, ML-KEM-1024, and ML-DSA-87. It provides the highest security level, including post-quantum protection.
- `PowerAuthAlgorithm.p384` uses P-384 without post-quantum protection. It offers excellent performance and stronger security than protocol 3.3, but should be used only when the infrastructure cannot handle the additional load of post-quantum algorithms.
- `PowerAuthAlgorithm.legacy` uses P-256 and PowerAuth protocol 3.3. It is intended for a staged migration to SDK 2.0. Switch to at least `p384` after upgrading PowerAuth Server to version 2.0.

The P-384 algorithms require PowerAuth Server version `2.0.0` or later. The legacy algorithm requires PowerAuth Server version `1.9.0` or later.

<!-- begin box info -->
The SDK can behave differently in some cases when `PowerAuthAlgorithm.legacy` is selected. Native documentation refers to this configuration as "legacy mode" and to its activations as "legacy activations."
<!-- end -->

Set the algorithm in the main configuration:

```dart
final configuration = PowerAuthConfiguration(
    configuration: "ARCB+/qxp........IQ5E5jg==",
    baseEndpointUrl: "https://<your-domain>/enrollment-server",
    algorithm: PowerAuthAlgorithm.p384l3,
    offlineAuthenticationCodeComponentLength: 8,
);
```

The `offlineAuthenticationCodeComponentLength` value must be from `4` through `8`. Its default value is `8`.

The selected algorithm cannot be changed on an already configured `PowerAuth` instance. It can be changed in a later application version. If the new algorithm does not match an activation already stored on the device, complete an [authenticated protocol upgrade](Requesting-Device-Activation-Status.md#authenticated-protocol-upgrade).

### Advanced configuration

In case you need an advanced configuration, you can import and use the following configuration classes:

- `PowerAuthClientConfiguration` class to configure internal HTTP client. You can alter the following parameters:
  - `enableUnsecureTraffic` - If HTTP or invalid HTTPS communication should be enabled (do not set `true` in production).
  - `connectionTimeout` - timeout in seconds. The default value is `20` seconds.
  - `readTimeout` - timeout in seconds, effective only on the Android platform. The default value is `20` seconds.
  - `customHttpHeaders` - custom HTTP headers that will be added to each HTTP request produced by the PowerAuth instance.
  - `basicHttpAuthentication` - basic HTTP Authentication will be added to each HTTP request produced by the PowerAuth instance.

- `PowerAuthBiometryConfiguration` class to configure biometric authentication. You can alter the following parameters:
  - `invalidateBiometricFactorAfterChange` - set to `true` to invalidate the biometric factor if the user changes the enrolled biometric data. The default value depends on the platform:
    - On Android is set to `true`
    - On iOS  is set to `false`
  - `fallbackToDevicePasscode` - iOS specific, If set to `true`, then the key protected with the biometry can be accessed also with a device passcode. If set, then the `invalidateBiometricFactorAfterChange` option has no effect. The default is `false`, so the fallback to the device's passcode is not enabled.
  - `confirmBiometricAuthentication` - Android specific, if set to `true`, then the user's confirmation will be required after the successful biometric authentication. The default value is `false`.
  - `authenticateOnBiometricKeySetup` - Android specific, if set to `true`, then the biometric key setup always requires a biometric authentication. See note<sup>1</sup> below. The default value is `true`.
  - `fallbackToSharedBiometryKey` - Android specific, defines whether the SDK searches for the shared biometric key from SDK 1.x. The default value is `true`. Set this option to `false` if your application uses multiple `PowerAuth` instances.
  - `useLegacySymmetricKey` - Android specific, uses the legacy AES-KDF protection for new biometric factors. This option is for testing only. Keep the default value of `false` in production.

- `PowerAuthKeychainConfiguration` class configures internal secure data storage on Android:
  - `minimalRequiredKeychainProtection` - defines the minimum keychain protection level that the device must support. The default value is `PowerAuthKeychainProtection.none`. See note<sup>2</sup> below.

- `PowerAuthSharingConfiguration` class to configure activation data sharing on the iOS platform. You can alter the following parameters:
  - `appGroup` - defines the name of the app group that allows you to share data between multiple applications.
  - `appIdentifier`- defines a unique application identifier. This identifier helps you to determine which application currently holds the lock on activation data in special operations.
  - `keychainAccessGroup` - defines the keychain access group name used by the PowerAuthSDK keychain instances.
  - For Apple entitlements, shared instance identifiers, and external-operation handling, see [Activation Data Sharing](Activation-Data-Sharing.md).

> Note 1: Setting `authenticateOnBiometricKeySetup` to `true` uses HMAC-KDF. Biometric authentication is required to configure and use the key. Setting it to `false` uses RSA. Biometric authentication is required only to use the key.

> Note 2: If you enforce protection higher than `PowerAuthKeychainProtection.none`, then your application must target Android 6.0 or later. Handle `PowerAuthErrorCode.insufficientKeychainProtection` when a device cannot provide the required protection.

<!-- begin box warning -->
Do not enable `fallbackToDevicePasscode` when your application must distinguish biometric authentication from knowledge-factor authentication, including applications subject to regulations that require a biometric factor. If the key is unlocked with the device passcode, the resulting authentication is no longer proof that the user authenticated with biometry.
<!-- end -->

The following code snippet shows usage of the advanced configuration:

```dart
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

Future<void> initPowerauth() async {
    final powerAuth = PowerAuth("your-app-instance-id");
    
    // An already configured instance will throw an
    // exception when you try to configure it again
    if (await powerAuth.isConfigured()) {
        print("PowerAuth was already configured.");
    } else {
        try {
            final configuration = PowerAuthConfiguration(
                configuration: "ARCB+/qxp........IQ5E5jg==",
                baseEndpointUrl: "https://<your-domain>/enrollment-server",
            );
            final clientConfiguration = PowerAuthClientConfiguration(enableUnsecureTraffic: false);
            final biometryConfiguration = PowerAuthBiometryConfiguration(
                invalidateBiometricFactorAfterChange: true,
            );
            final keychainConfiguration = PowerAuthKeychainConfiguration(minimalRequiredKeychainProtection: PowerAuthKeychainProtection.software);
            // This is iOS specific. All values will be ignored on the Android platform.
            // All the following values are fake. Please read the native PowerAuth mobile SDK documentation
            // about activation data sharing that explains how to prepare parameters in detail.
            final sharingConfiguration = PowerAuthSharingConfiguration(
                appGroup: "group.your.app.group", 
                appIdentifier: "some.identifier", 
                keychainAccessGroup: "keychain.access.group",
            );
            await powerAuth.configure(
                configuration: configuration,
                biometryConfiguration: biometryConfiguration,
                clientConfiguration: clientConfiguration,
                keychainConfiguration: keychainConfiguration,
                sharingConfiguration: sharingConfiguration
            );
            
            // powerAuth object configured
              
        } on PowerAuthException catch (configError) {
            print("PowerAuth configuration failed (Code: ${configError.code}, msg: ${configError.message}). ");
        } catch (configError) {
            print("Failed to auto-configure PowerAuth (Unknown Error): $configError");
        }
    }
}
```

The configuration properties are asynchronous because the effective values come from the native SDK:

```dart
final configuration = await powerAuth.configuration;
final currentAlgorithm = await powerAuth.currentAlgorithm;
final clientConfiguration = await powerAuth.clientConfiguration;
final biometryConfiguration = await powerAuth.biometryConfiguration;
final keychainConfiguration = await powerAuth.keychainConfiguration;
final sharingConfiguration = await powerAuth.sharingConfiguration;
```

The client configuration does not return `customHttpHeaders` or `basicHttpAuthentication`. Keep the original configuration if you must use these values again.

The native SDKs also provide platform-specific HTTP extension points that cannot be represented by the common Dart configuration.

### Instance and Local State

Use these local methods to inspect the activation before starting an operation:

```dart
final configured = await powerAuth.isConfigured();
final hasActivation = await powerAuth.hasValidActivation();
final canStart = await powerAuth.canStartActivation();
final activationPending = await powerAuth.hasPendingActivation();
final activationId = await powerAuth.getActivationIdentifier();
final activationFingerprint = await powerAuth.getActivationFingerprint();
```

`getActivationIdentifier()` and `getActivationFingerprint()` return `null` when no valid activation is available. These values are local and do not fetch the latest server state.

`deconfigure()` removes the configured native instance from the wrapper registry and invalidates native-backed objects associated with it. It does not remove the persisted activation from the device or PowerAuth Server. A later configuration with the same values can load that activation again. Use activation-removal APIs when activation data must be deleted.

```dart
await powerAuth.deconfigure();
```

### Configuration Recovery

If configuration fails with `PowerAuthErrorCode.invalidActivationData`, the local activation data has an incompatible format. Call `cleanupInstanceData()` with the same main, keychain, and sharing configurations. Then configure the instance again.

```dart
await powerAuth.cleanupInstanceData(
    configuration: configuration,
    keychainConfiguration: keychainConfiguration,
    sharingConfiguration: sharingConfiguration,
);
await powerAuth.configure(
    configuration: configuration,
    clientConfiguration: clientConfiguration,
    biometryConfiguration: biometryConfiguration,
    keychainConfiguration: keychainConfiguration,
    sharingConfiguration: sharingConfiguration,
);
```

<!-- begin box warning -->
`cleanupInstanceData()` deletes local activation data. Call it only after an `invalidActivationData` error. If configuration fails with `PowerAuthErrorCode.upgradeSdk`, update the application to a newer SDK. Do not delete the activation data.
<!-- end -->

## Read Next

- [Device Activation](./Device-Activation.md)
