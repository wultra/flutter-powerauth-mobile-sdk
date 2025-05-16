import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

abstract class TestSuite {

  List<ExpectResult> singleTestResults = [];
  List<Object> cleanup = [];
  var testFailCount = 0;

  List<Future<void> Function()> getTests();

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
      print("  Test finished with ${failedResultsCount} failed asserts out of ${singleTestResults.length}");
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

  Future<void> toBe(Object other, {String message = ""}) async {
    var self = await this;
    self.isResultExpected = self.result == other;
    if (!self.isResultExpected) {
      if (self.exception != null) {
        print("expected $other, but got ${self.exception} instead");
      } else {
        print("value ${self.result} does not equal $other - $message");
      }
    }
  }

  Future<void> toThrow(PowerAuthErrorCode code, {String message = ""}) async {
    var self = await this;
    var exception = self.exception;
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