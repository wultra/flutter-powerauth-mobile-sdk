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

import 'dart:async';

import 'package:integration_test/integration_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

// A simple helper to wrap potentially async main functions.
// Useful for when you need to call top-level async functions in the test's main.
Future<void> _runSuite(Function suiteMain) async {
  final Object? result = Function.apply(suiteMain, const []);

  if (result is Future) {
    await result;
  }
}

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Proactively load the env so that tests run correctly from the IDE
  // AND we don't have to import it from the example app or in each suite
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Register (and run) all suites
  await _runSuite(utils_suite.main);
  await _runSuite(password_suite.main);
  await _runSuite(configure_suite.main);
  await _runSuite(activation_suite.main);
  await _runSuite(encryptor_suite.main);
  await _runSuite(native_obj_suite.main);
  await _runSuite(powerauth_password_suite.main);
  await _runSuite(signature_suite.main);
  await _runSuite(time_suite.main);
  await _runSuite(token_suite.main);
  await _runSuite(userinfo_suite.main);
  await _runSuite(biometrics_automated_suite.main);
  await _runSuite(cryptoutils_suite.main);
}
