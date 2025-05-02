import 'package:flutter_dotenv/flutter_dotenv.dart';

/// General PWA config loaded from [.env] file.
class AppConfig {

  /// Base URL of the PowerAuth server instance.
  static final String baseUrl =
      dotenv.env['POWERAUTH_BASE_URL'] ?? 'https://powerauth-dev.westeurope.cloudapp.azure.com/powerauth-java-server';

  /// Config string
  static final String powerAuthConfigString =
      dotenv.env['POWERAUTH_CONFIG_STRING'] ?? '';

  AppConfig._();

  /// Helper for confing requirement.
  static bool isConfigMissing() {
    return powerAuthConfigString.isEmpty;
  }
}
