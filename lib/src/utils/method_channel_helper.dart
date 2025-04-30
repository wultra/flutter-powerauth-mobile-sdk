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

import 'package:flutter/services.dart';
import '../model/powerauth_error.dart'; // Assuming PowerAuthError definitions are here

/// Helper mixin for invoking methods on a provided MethodChannel and handling PowerAuth errors.
mixin MethodChannelHelper {

  MethodChannel get methodChannel;

  /// Invokes a method expecting a non-null result.
  Future<T> invokeMethod<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final result = await methodChannel.invokeMethod<T>(method, arguments);
  
      // Handle cases where native side might return null unexpectedly for non-nullable types
      if (result == null && null is! T) {
        throw PowerAuthException(
          code: PowerAuthErrorCode.unknownError,
          message: 'Native method \'$method\' returned null unexpectedly.',
        );
      }
  
      // Return the actual data
      return result as T;
    } on PlatformException catch (e) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.values.firstWhere(
          (code) => code.name == e.code,
          orElse: () => PowerAuthErrorCode.unknownError,
        ),
        message: e.message,
        errorData:
            e.details is Map ? Map<String, dynamic>.from(e.details) : null,
        cause: e,
      );

    } catch (e) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.unknownError,
        message:
            'Unexpected error invoking method \'$method\': ${e.toString()}',
        cause: e,
      );
    }
  }

  /// Invokes a method that might return a null result.
  Future<T?> invokeNullableMethod<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      return await methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.values.firstWhere(
          (code) => code.name == e.code,
          orElse: () => PowerAuthErrorCode.unknownError,
        ),
        message: e.message,
        errorData:
            e.details is Map ? Map<String, dynamic>.from(e.details) : null,
        cause: e,
      );

    } catch (e) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.unknownError,
        message:
            'Unexpected error invoking nullable method \'$method\': ${e.toString()}',
        cause: e,
      );
    }
  }
}
