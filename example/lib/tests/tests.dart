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

import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/powerauth_biometrics_interactive_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/powerauth_biometrics_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/powerauth_cryptoutils_tests.dart';

class Tests {

  final _testSuites = [
      PowerAuthCryptoUtilsTests(),
      PowerAuthBiometricsTests(),
      PowerauthBiometricsInteractiveTests(),
    ];

  Future<TestResult> run({bool interactive = false}) async {
    final testSuites = _testSuites.where((testSuite) => testSuite.isInteractive == interactive).toList();
    //PowerAuthDebug.traceNativeCodeCalls(traceEachCall: false, traceFailure: false);
    print("\n\n### ${interactive ? "Interactive" : "Non-interactive"} tests starting...");
    for (var testSuite in testSuites) {
      await testSuite.runTests();
    }
    final failedTests = testSuites.where((testSuite) => testSuite.testFailCount > 0);
    final result = TestResult("${testSuites.length} suites finished with ${failedTests.length} failed tests ${failedTests.isNotEmpty ? "❌❌❌" : "✅✅✅"}");
    return result;
  }
}

class TestResult {
  // TODO: add some statistics in the future
  final String text;
  TestResult(this.text);
}