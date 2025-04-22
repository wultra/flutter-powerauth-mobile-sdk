import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'powerauth_method_channel.dart';

abstract class PowerAuthPlatform extends PlatformInterface {
  /// Constructs a FlutterPowerauthMobileSdkPluginPlatform.
  PowerAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthPlatform _instance = PowerAuthMethodChannel();

  /// The default instance of [PowerAuthPlatform] to use.
  ///
  /// Defaults to [PowerAuthMethodChannel].
  static PowerAuthPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PowerAuthPlatform] when
  /// they register themselves.
  static set instance(PowerAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
