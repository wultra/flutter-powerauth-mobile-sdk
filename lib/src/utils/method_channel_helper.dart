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

import 'dart:convert';

import 'package:flutter/services.dart';
import '../model/powerauth_error.dart';
import '../logging/powerauth_logger.dart';

/// Helper mixin for invoking methods on a provided MethodChannel and handling PowerAuth errors.
mixin MethodChannelHelper {

  /// The method channel used for invoking native methods.
  MethodChannel get methodChannel;

  /// The tracer for method calls. By default, it is set to a no-operation tracer.
  static CallTracer callTracer = NoOpCallTracer();

  /// Invokes a method expecting a non-null result.
  Future<T> invokeMethod<T>(String method, Map<String, dynamic>? arguments) async {
    return await callTracer.traceCall(method, arguments, () => _invokeMethodChannelMethod<T>(method, arguments, false)) as T;
  }

  /// Invokes a method that might return a null result.
  Future<T?> invokeNullableMethod<T>(String method, Map<String, dynamic>? arguments) async {
    return await callTracer.traceCall(method, arguments, () => _invokeMethodChannelMethod<T>(method, arguments, true));
  }

  Future<T?> _invokeMethodChannelMethod<T>(String method, Map<String, dynamic>? arguments, bool nullableResult) async {
    try {
      final result = await methodChannel.invokeMethod<T>(method, arguments);
      // If the result is null and we expect a non-nullable type, throw an exception.
      if (nullableResult == false && result == null && null is! T) {
        throw PowerAuthException(
          code: PowerAuthErrorCode.unknownError,
          message: 'Native method \'$method\' returned null unexpectedly.',
        );
      }
      return result;
    } on PlatformException catch (e) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.values.firstWhere(
          (code) => code.name == e.code,
          orElse: () => PowerAuthErrorCode.unknownError,
        ),
        message: e.message,
        errorData: e.details is Map ? Map<String, dynamic>.from(e.details) : null,
        cause: e,
      );

    } catch (e) {

      throw PowerAuthException(
        code: PowerAuthErrorCode.unknownError,
        message: 'Unexpected error invoking method \'$method\': ${e.toString()}',
        cause: e
      );
    }
  }
}

/// An interface for tracing method calls. Implementations can log, measure, or handle
/// method calls in any way they see fit. This is useful for debugging or performance monitoring.
abstract class CallTracer {
  Future<T?> traceCall<T>(String name, Map<String, dynamic>? arguments, Future<T?> Function() call);
}

/// A no-operation tracer that does nothing. This is the default tracer and can be used
/// when tracing is not needed or desired.
class NoOpCallTracer implements CallTracer {
  @override
  Future<T?> traceCall<T>(String method, Map<String, dynamic>? arguments, Future<T?> Function() call) {
    return call();
  }
}

/// A simple tracer that prints method calls and their results to the console.
/// This is useful for debugging but should not be used in production code.
class DebugCallTracer implements CallTracer {

  final bool _traceCall;
  final bool _traceFail;
  // TODO: add time measurement?

  DebugCallTracer(this._traceCall, this._traceFail);

  @override
  Future<T?> traceCall<T>(String method, Map<String, dynamic>? arguments, Future<T?> Function() call) async {
    final msg = "PowerAuth.$method(${arguments?.entries.map((e) => '${e.key}: ${e.value}').join(', ')})";
    if (_traceCall) {
      PowerAuthLogger.debug("call $msg");
    }

    try {
      final result = await call();
      if (_traceCall) {
        PowerAuthLogger.debug("ret $msg => ${jsonEncode(result)}");
      }

      return result;
    } catch (e) {
      if (_traceFail) {
        PowerAuthLogger.debug("fail $msg => $e");
      }

      rethrow;
    }
  }
}
