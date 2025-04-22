import 'powerauth_platform_interface.dart';

class PowerAuth {
  Future<String?> getPlatformVersion() {
    return PowerAuthPlatform.instance.getPlatformVersion();
  }
}
