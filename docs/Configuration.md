# Configuration

Before you call any method on the newly created `final powerAuth = PowerAuth(instanceId);` object, you need to configure it first. An unconfigured instance will throw exceptions. Use `await powerAuth.isConfigured();` to check if configured.

## 1. Parameters

You will need the following parameters to prepare and configure a PowerAuth instance:

- **instanceId** - Identifier of the app - the application package name/identifier is recommended.
- **configuration** - String (base64) with the cryptographic configuration - this configuration can be retrieved via the `Get App Details` Admin API in the PowerAuth Cloud server component.
- **baseEndpointUrl** - Base URL to the PowerAuth Standard RESTful API. _(usualy sometihng like `https://<your-domain>/enrollment-server`)_

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

### Advanced configuration

In case you need an advanced configuration, you can import and use the following configuration classes:

- `PowerAuthClientConfiguration` class to configure internal HTTP client. You can alter the following parameters:
  - `enableUnsecureTraffic` - If HTTP or invalid HTTPS communication should be enabled (do not set `true` in production).
  - `connectionTimeout` - timeout in seconds. The default value is `20` seconds.
  - `readTimeout` - timeout in seconds, effective only on the Android platform. The default value is `20` seconds.
  - `customHttpHeaders` - custom HTTP headers that will be added to each HTTP request produced by the PowerAuth instance.
  - `basicHttpAuthentication` - basic HTTP Authentication will be added to each HTTP request produced by the PowerAuth instance.

- `PowerAuthBiometryConfiguration` class to configure biometric authentication. You can alter the following parameters:
  - `linkItemsToCurrentSet` - set to `true` if the key protected with the biometry is invalidated if fingers are added or removed, or if the user re-enrolls for face. The default value depends on the platform:
    - On Android is set to `true`
    - On iOS  is set to `false`
  - `fallbackToDevicePasscode` - iOS specific, If set to `true`, then the key protected with the biometry can be accessed also with a device passcode. If set, then the `linkItemsToCurrentSet` option has no effect. The default is `false`, so the fallback to the device's passcode is not enabled.
  - `confirmBiometricAuthentication` - Android specific, if set to `true`, then the user's confirmation will be required after the successful biometric authentication. The default value is `false`.
  - `authenticateOnBiometricKeySetup` - Android specific, if set to `true`, then the biometric key setup always requires a biometric authentication. See note<sup>1</sup> below. The default value is `true`.

- `PowerAuthKeychainConfiguration` class to configure an internal secure data storage. You can alter the following parameters:
  - `accessGroupName` - iOS specific, defines access group name used by the `PowerAuth` keychain instances. This is useful in situations when your application is sharing data with another application or an application's extension from the same vendor. The default value is `null`. See note<sup>2</sup> below.
  - `userDefaultsSuiteName` - iOS specific, defines the suite name used by the `UserDefaults` that check for Keychain data presence. This is useful in situations when your application is sharing data with another application or an application's extension from the same vendor. The default value is `null`. See note<sup>2</sup> below.
  - `minimalRequiredKeychainProtection` - Android specific, defines the minimal required keychain protection level that must be supported on the current device. The default value is `PowerAuthKeychainProtection.NONE`. See note<sup>3</sup> below.
  - `fallbackToSharedBiometryKey` - Android specific, defines whether fallback to a shared, legacy biometry key is enabled. By default, this is enabled for compatibility reasons. If your application uses multiple `PowerAuth` instances, it's recommended to set this configuration to `false`.

- `PowerAuthSharingConfiguration` class to configure activation data sharing on the iOS platform. You can alter the following parameters:
  - `appGroup` - defines the name of the app group that allows you to share data between multiple applications. Be aware that the value overrides the `accessGroupName` property if it's provided in `PowerAuthKeychainConfiguration`.
  - `appIdentifier`- defines a unique application identifier. This identifier helps you to determine which application currently holds the lock on activation data in special operations.
  - `keychainAccessGroup` - defines the keychain access group name used by the PowerAuthSDK keychain instances.
  - `sharedMemoryIdentifier` - defines an optional identifier of memory shared between the applications in the app group. If identifier is not provided then PowerAuthSDK calculate unique identifier based on `PowerAuth.instanceId`.
  - If you're not familiar with sharing data between iOS applications or app extensions, then please refer to the native PowerAuth mobile SDK documentation, where this topic is explained in more detail. 


> Note 1: Setting `authenticateOnBiometricKeySetup` parameter to `true` leads to using symmetric AES cipher in the background, so both configuration and usage of biometric key require the biometric authentication. If set to `false`, then the RSA cipher is used, and only the usage of the biometric key requires the biometric authentication. This is due to the fact that the RSA cipher can encrypt data using its public key, available immediately after the key pair is created in Android KeyStore.

> Note 2: You're responsible for migrating the keychain and `UserDefaults` data from non-shared storage to the shared one, before you configure the first `PowerAuth` instance. This is quite difficult to do in Flutter, so it's recommended not to alter `PowerAuthKeychainConfiguration` once your application is already shipped in the App Store.

> Note 3: If you enforce the protection higher than `PowerAuthKeychainProtection.none`, then your application must target at least Android 6.0. Your application should also properly handle the `PowerAuthErrorCode.insufficientKeychainProtection` error code reported when the device has insufficient capabilities to run your application. You should properly inform the user about this situation.

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
            final biometryConfiguration = PowerAuthBiometryConfiguration(linkItemsToCurrentSet: true);
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
                configuration: powerAuthConfig,
                biometryConfiguration: biometryConfig,
                clientConfiguration: clientConfig,
                keychainConfiguration: keychainConfig,
                sharingConfiguration: sharingConfig
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

## Read Next

- [Device Activation](./Device-Activation.md)

