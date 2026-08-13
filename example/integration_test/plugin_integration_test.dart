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

import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'suites/utils_test.dart' as utils_suite;
import 'suites/password_test.dart' as password_suite;
import 'suites/powerauth_activation_test.dart' as activation_suite;
import 'suites/powerauth_configure_test.dart' as configure_suite;
import 'suites/powerauth_encryptor_test.dart' as encryptor_suite;
import 'suites/powerauth_native_object_register_test.dart' as native_obj_suite;
import 'suites/powerauth_password_test.dart' as powerauth_password_suite;
import 'suites/powerauth_signature_test.dart' as signature_suite;
import 'suites/powerauth_time_test.dart' as time_suite;
import 'suites/powerauth_token_test.dart' as token_suite;
import 'suites/powerauth_userinfo_test.dart' as userinfo_suite;
import 'suites/powerauth_biometrics_automated_test.dart'
    as biometrics_automated_suite;
import 'suites/powerauth_cryptoutils_tests.dart' as cryptoutils_suite;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  });

  utils_suite.main();
  password_suite.main();
  configure_suite.main();
  activation_suite.main();
  encryptor_suite.main();
  native_obj_suite.main();
  powerauth_password_suite.main();
  signature_suite.main();
  time_suite.main();
  token_suite.main();
  userinfo_suite.main();
  biometrics_automated_suite.main();
  cryptoutils_suite.main();
}
