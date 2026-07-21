/*
 * Copyright 2026 Wultra s.r.o.
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

import '../logging/powerauth_logger.dart';
import '../powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import 'powerauth_error.dart';

/// Owns the lifecycle of one object stored in the native object register.
class NativeObjectHandle {
  NativeObjectHandle.fromNative(String objectId)
    : _objectId = objectId,
      _initializer = null;

  NativeObjectHandle.lazy(Future<String> Function() initializer)
    : _initializer = initializer;

  static NativeObjectRegisterPlatform get _platform =>
      NativeObjectRegisterPlatform.instance;

  final Future<String> Function()? _initializer;
  String? _objectId;
  Future<String>? _initialization;
  Future<void>? _releaseFuture;
  bool _releaseRequested = false;

  Future<String> getObjectId() async {
    if (_releaseRequested) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.invalidNativeObject,
        message: 'Object has already been released.',
      );
    }

    final objectId = _objectId;
    if (objectId != null) {
      return objectId;
    }

    final initializer = _initializer;
    if (initializer == null) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.invalidNativeObject,
        message: 'Native object is not initialized.',
      );
    }

    final initialization = _initialization ??= initializer();
    try {
      final initializedObjectId = await initialization;
      if (_releaseRequested) {
        throw PowerAuthException(
          code: PowerAuthErrorCode.invalidNativeObject,
          message: 'Object has already been released.',
        );
      }
      _objectId = initializedObjectId;
      return initializedObjectId;
    } catch (_) {
      if (identical(_initialization, initialization) && !_releaseRequested) {
        _initialization = null;
      }
      rethrow;
    }
  }

  Future<T> withObjectId<T>(
    Future<T> Function(String objectId) operation,
  ) async {
    return operation(await getObjectId());
  }

  Future<void> release() {
    // A lazy handle has no native resource to release before initialization starts
    if (!_releaseRequested && _objectId == null && _initialization == null) {
      return Future<void>.value();
    }
    return _releaseFuture ??= _release();
  }

  Future<void> _release() async {
    _releaseRequested = true;

    String? objectId = _objectId;
    if (objectId == null && _initialization != null) {
      try {
        objectId = await _initialization;
      } catch (_) {
        return;
      }
    }

    _objectId = null;
    if (objectId == null) {
      return;
    }

    try {
      await _platform.releaseNativeObject(objectId);
    } catch (e) {
      PowerAuthLogger.warning(
        'Error during native release for object $objectId: $e',
      );
    }
  }
}
