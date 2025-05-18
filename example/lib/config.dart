import 'package:flutter_dotenv/flutter_dotenv.dart';

/// General PWA config loaded from [.env] file.
class AppConfig {

  /// Enrollment URL.
  static final String enrollmentUrl = dotenv.env['ENROLLMENT_URL'] ?? '';
  /// SDK Config string
  static final String sdkConfig = dotenv.env['SDK_CONFIG'] ?? '';

  /// PowerAuth Cloud URL.
  static final String cloudUrl = dotenv.env['CLOUD_URL'] ?? '';
  /// PowerAuth Cloud username.
  static final String cloudLogin = dotenv.env['CLOUD_LOGIN'] ?? '';
  /// PowerAuth Cloud password.
  static final String cloudPassword = dotenv.env['CLOUD_PASSWORD'] ?? '';
  /// PowerAuth Cloud application ID.
  static final String cloudApplicationId = dotenv.env['CLOUD_APPLICATION_ID'] ?? '';

  AppConfig._();

  /// Helper for confing requirement.
  static bool isConfigMissing() {
    return sdkConfig.isEmpty;
  }
}
