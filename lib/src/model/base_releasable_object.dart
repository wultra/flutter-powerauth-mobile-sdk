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

import 'package:meta/meta.dart';
import '../logging/powerauth_logger.dart';

/// Base class for objects that need to be released but don't require
/// full native object lifecycle management.
abstract class BaseReleasableObject {

  /// The native object identifier.
  String? objectId;

  /// Returns true if the underlying native object has been released.
  @protected
  bool get isReleased => _isReleased;
  bool _isReleased = false;

  /// Abstract method that subclasses must implement to release the native object.
  @protected
  Future<void> releaseNativeObject(String objectId);

  /// Releases the native object associated with this wrapper.
  /// The object becomes unusable after calling this method.
  Future<void> release() async {
    if (_isReleased || objectId == null) return;
    _isReleased = true;

    try {
      await releaseNativeObject(objectId!);
    } catch (e) {
      PowerAuthLogger.warning('${runtimeType.toString()}: Error during native release for object $objectId: $e');
    } finally {
      objectId = null;
    }
  }

  /// Helper method for subclasses to safely execute actions requiring the native object ID.
  @protected
  Future<T> withObjectId<T>(Future<T> Function(String objectId) action) async {
    if (_isReleased || objectId == null) {
      throw StateError('Object has already been released or not initialized.');
    }

    return await action(objectId!);
  }
}
