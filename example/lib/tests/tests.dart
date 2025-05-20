import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/activation_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/configuration_objects_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/configure_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/password_tests.dart';

class Tests {
  void run() async {
    var testSuites = [
      PowerAuthPasswordTests(),
      ConfigureTests(),
      ConfigurationObjectsTests(),
      ActivationTests()
    ];
    print("\n\n###  Test starting...");
    for (var testSuite in testSuites) {
      await testSuite.runTests();
    }
    final failedTests = testSuites.where((testSuite) => testSuite.testFailCount > 0);
    print("### ${testSuites.length} suites finished with ${failedTests.length} failed tests ${failedTests.isNotEmpty ? "❌❌❌" : "✅✅✅"}");
  }
}