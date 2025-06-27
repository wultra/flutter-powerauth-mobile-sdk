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
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

abstract class TestSuite {

  // Metho to be implemented by subclasses to provide a list of tests.
  List<Future<void> Function()> getTests();

  List<ExpectResult> singleTestResults = [];
  List<Object> cleanup = [];
  var testFailCount = 0;
  bool isInteractive = false; // Set to true if the test suite expects user interaction)
  String? currentTestName;

  String get name {
    return toString().replaceAll("Instance of ", "").replaceAll("'", "");
  }

  Future<void> beforeAll() async {
    // Default implementation does nothing
  }

  Future<void> afterAll() async {
    // Default implementation does nothing
  }

  Future<void> beforeEach() async {
    cleanup = [];
    singleTestResults = [];
  }

  Future<void> afterEach() async {
    for (var p in cleanup) {
      if (p is PowerAuthPassword) {
        await p.release();
      } else if (p is PowerAuth) {
        p.deconfigure();
      }
    }
    var failedResultsCount = singleTestResults.where((result) => !result.isResultExpected).length;
    if (failedResultsCount > 0) {
      print("  Test finished with $failedResultsCount failed asserts out of ${singleTestResults.length}");
      testFailCount += 1;
    } else {
      print("  All ${singleTestResults.length} asserts passed");
    }
  }

  Future<void> runTests() async {
    print("------------------------");
    print("🏁 $name: Test suite starting");
    print("Running ${getTests().length} tests");
    await beforeAll();
    for (var test in getTests()) {
      currentTestName = test.toString().replaceFirst("Closure: () => Future<void> from Function ", "").replaceAll("'", "").replaceAll(":", "").replaceAll(".", "");
      print("- Running $currentTestName");
      await beforeEach();
      try {
        await test();
      } catch (e) {
        print("  Test failed with exception: $e");
        testFailCount += 1; // TODO: this should be handled better
      }
      await afterEach();
    }
    await afterAll();

    print("${testFailCount > 0 ? "😢" : "😎"} Test suite $name finished with $testFailCount failed tests");
    print("");
  }

  Future<ExpectResult> expect(Object? o) async {
    var result = ExpectResult(o, null);
    if (o is Future) {
      try {
        var callResult = await o;
        result = ExpectResult(callResult, null);
      } catch (e) {
        result = ExpectResult(null, e);
      }
    }
    singleTestResults.add(result);
    return result;
  }

  void reportFailure(String message) {
    // TODO: this should be handled better
    print("  Test $currentTestName failed with message: $message");
    final result = ExpectResult(null, null);
    result.isResultExpected = false;
    singleTestResults.add(result);
  }

  Future<void> sleep(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  Future<void> showPrompt(String text, {UserPromptDuration duration = UserPromptDuration.normal}) async {
    // TODO: this should be displayed in the UI
    print(text);
  }
}

enum UserPromptDuration {
  quick,
  normal
}

abstract class TestSuiteWithActivation extends TestSuite {
  
  @protected late IntegrationHelper helper;
  @protected late PowerAuth sdk;
  @protected late ActivationCredentials credentials;

  @override
  Future<void> beforeEach() async {
    await super.beforeEach();
    credentials = ActivationCredentials();
    sdk = PowerAuth(IntegrationHelper.randomString(30));
    helper = IntegrationHelper(sdk);
    await helper.configure();
  }

  @override
  Future<void> afterEach() async {
    await helper.cleanup();
    await super.afterEach();
  }
}

class ExpectResult {

  Object? result;
  Object? exception;
  bool isResultExpected = false;

  ExpectResult(this.result, this.exception);
}

extension FutureExpectResult on Future<ExpectResult> {

  Future<void> toBeDefined({String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.result != null;
    if (!self.isResultExpected) {
      if (self.exception != null) {
        print("expected null, but got ${self.exception} instead");
      } else {
        print("value is null - $message");
      }
    }
  }

  Future<void> toBeNull({String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.result == null;
    if (!self.isResultExpected) {
      if (self.exception != null) {
        print("expected null, but got ${self.exception} instead");
      } else {
        print("value ${self.result} is not null - $message");
      }
    }
  }

  Future<void> toBe(Object? other, {String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.result == other;
    if (!self.isResultExpected) {
      if (self.exception != null) {
        print("expected $other, but got ${self.exception} instead - $message");
      } else {
        print("Retrieved value ${self.result} does not equal expected value $other - $message");
      }
    }
  }

  Future<void> notToBe(Object? other, {String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.result != other;
    if (!self.isResultExpected) {
      if (self.exception != null) {
        print("expected $other, but got ${self.exception} instead");
      } else {
        print("Retrieved value ${self.result} should differ, but it's the same - $message");
      }
    }
  }

  Future<void> toThrow(PowerAuthErrorCode code, {String message = ""}) async {
    final self = await this;
    final exception = self.exception;
    self.isResultExpected = exception is PowerAuthException && exception.code == code;

    if (!self.isResultExpected) {
      print("expected to throw $code, but got exception: ${self.exception}, value: ${self.result} - $message");
    }
  }

  Future<void> toSucceed({String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.exception == null;
    if (!self.isResultExpected) {
      print("expected to succeed, but got exception: ${self.exception}, value: ${self.result} - $message");
    }
  }
}

class ActivationCredentials {
    /// String with a valid password.
    late String validPassword;
    /// String with an invalid password.
    late String invalidPassword;

    ActivationCredentials() {
      final availablePasswords = [ "VerySecure", "1234", "nbusr123", "39h132v,kJdfvAl", "98765", "correct horse battery staple" ];
      final validIndex = Random().nextInt(availablePasswords.length);
      validPassword = availablePasswords[validIndex];
      invalidPassword = availablePasswords[(validIndex + 1) % availablePasswords.length];
    }

    PowerAuthAuthentication possession() => PowerAuthAuthentication.possession();
    PowerAuthAuthentication biometry() => PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(
        promptTitle: 'Authenticate',
        promptMessage: 'Please authenticate with biometry'
    ));
    Future<PowerAuthAuthentication> knowledge() async => PowerAuthAuthentication.password(await validPasswordObject());
    Future<PowerAuthAuthentication> invalidKnowledge() async => PowerAuthAuthentication.password(await invalidPasswordObject());
    Future<PowerAuthPassword> validPasswordObject({bool destroyOnUse = true}) => PowerAuthPassword.fromString(validPassword, destroyOnUse: destroyOnUse);
    Future<PowerAuthPassword> invalidPasswordObject({bool destroyOnUse = true}) => PowerAuthPassword.fromString(invalidPassword, destroyOnUse: destroyOnUse);
}