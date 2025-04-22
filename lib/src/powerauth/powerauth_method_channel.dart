import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'powerauth_platform_interface.dart';

class PowerAuthMethodChannel extends PowerAuthPlatform {

  @visibleForTesting
  final methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
