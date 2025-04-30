# Configuration

Before you call any method on the newly created `final powerAuth = PowerAuth(instanceId);` object, you need to configure it first. An unconfigured instance will throw exceptions. Use `await powerAuth.isConfigured();` to check if configured.

## 1. Parameters

You will need the following parameters to prepare and configure a PowerAuth instance:

- **instanceId** - Identifier of the app - the application package name/identifier is recommended.
- **configuration** - String (base64) with the cryptographic configuration - this configuration can be retrieved via the `Get App Details` Admin API in the [PowerAuth Cloud](https://developers.wultra.com/components/powerauth-cloud) server component.
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

<!-- begin box info -->
Advanced configuration is not available for the Flutter platform in the current version. Until implemented, you can visit [PowerAuth Mobile JS SDK](https://github.com/wultra/react-native-powerauth-mobile-sdk) documentation to explore what advanced configuration is.
<!-- end -->

## Read Next

- [Device Activation](./Device-Activation.md)

