/*
 * Copyright 2025 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// General PWA config loaded from [.env] file.
class AppConfig {
  AppConfig._();

  static final Future<void> _initialized = ensureLoaded();

  /// Ensures the .env is loaded. Safe to call repeatedly.
  static Future<void> ensureLoaded() async {
    if (dotenv.isInitialized) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }

  static String _get(String key) {
    // ignore: unnecessary_statements
    _initialized;
    return dotenv.env[key] ?? '';
  }

  /// Enrollment URL.
  static String get enrollmentUrl => _get('ENROLLMENT_URL');

  /// SDK Config string
  static String get sdkConfig => _get('SDK_CONFIG');

  /// PowerAuth Cloud URL.
  static String get cloudUrl => _get('CLOUD_URL');

  /// PowerAuth Cloud username.
  static String get cloudLogin => _get('CLOUD_LOGIN');

  /// PowerAuth Cloud password.
  static String get cloudPassword => _get('CLOUD_PASSWORD');

  /// PowerAuth Cloud application ID.
  static String get cloudApplicationId => _get('CLOUD_APPLICATION_ID');

  /// Helper for confing requirement.
  static bool isConfigMissing() {
    return sdkConfig.isEmpty;
  }
}
