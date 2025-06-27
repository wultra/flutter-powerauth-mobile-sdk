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
