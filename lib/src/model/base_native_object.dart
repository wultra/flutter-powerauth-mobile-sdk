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

import '../model/powerauth_error.dart';

/// Abstract base class for Dart objects that wrap a native counterpart
/// identified by an object ID. Handles semi-lazy initialization and release.
abstract class BaseNativeObject {

  /// The native object identifier. Null until the native object is initialized.
  String? objectId;

  // Lock to prevent race conditions during lazy initialization
  final Completer<String> _initCompleter = Completer<String>();
  bool _isInitializing = false;
  bool _isReleased = false;

  /// Returns true if the underlying native object has been released.
  @protected
  bool get isReleased => _isReleased;

  /// Abstract method that subclasses must implement to create the native object.
  /// Should return the unique object ID assigned by the native side.
  @protected
  Future<String> createNativeObject();

  /// Abstract method that subclasses must implement to release the native object.
  @protected
  Future<void> releaseNativeObject(String objectId);

  /// Ensures the native object is initialized and returns its ID.
  /// Handles concurrent initialization attempts.
  @protected
  Future<String> ensureNativeObjectInitialized() async {
  
    // TODO: not sure whether we want to throw or simply log
    if (_isReleased) {
      throw PowerAuthException(
        code: PowerAuthErrorCode.invalidNativeObject,
        message: 'Object has already been released.',
      );
    }

    // If already initialized or initialization is complete, return ID (or its future)
    if (objectId != null) return objectId!;
    if (_initCompleter.isCompleted) return await _initCompleter.future;

    // TODO(post-beta): this locking might be a slight overkill, but let's be safe
    if (_isInitializing) {
      return await _initCompleter.future;
    }

    _isInitializing = true;

    try {
      final id = await createNativeObject();
      objectId = id;
      _initCompleter.complete(id);
      _isInitializing = false;

      return id;

    } catch (e) {
      _isInitializing = false;

      rethrow;
    }
  }

  /// Releases the native object associated with this wrapper.
  /// The object becomes unusable after calling this method.
  Future<void> release() async {

    String? idToRelease = objectId;

    if (_isReleased || idToRelease == null) return;
    _isReleased = true;

    if (_isInitializing && !_initCompleter.isCompleted) {
      print(
        "${runtimeType.toString()}: Release called while initialization was pending.",
      );
      try {
  
        // Wait a short time for initialization to potentially finish
        idToRelease = await _initCompleter.future.timeout(
          const Duration(milliseconds: 200),
        );
      } catch (_) {
  
        // Initialization failed or timed out, likely nothing to release on native side
        idToRelease = null;
        print(
          "${runtimeType.toString()}: Initialization failed or timed out before release.",
        );
      }
    }

    objectId = null;
    _isInitializing = false;

    if (idToRelease != null) {
      try {
        await releaseNativeObject(idToRelease);
      } catch (e) {
        print(
          "${runtimeType.toString()}: Error during native release for object $idToRelease: $e",
        );
      }
    }
  }

  /// Allows subclasses that receive a pre-initialized object ID to mark
  /// the base class initialization as complete.
  @protected
  void completeInitialization(String initialObjectId) {
    if (objectId == null && !_initCompleter.isCompleted) {
      objectId = initialObjectId;
      _isInitializing = false; // Not initializing anymore
      _initCompleter.complete(initialObjectId);
    } else {
      // TODO: do we also want to throw?
      print(
        "${runtimeType.toString()}: Warning - completeInitialization called when already initialized or initializing.",
      );
    }
  }

  /// Helper method for subclasses to safely execute actions requiring the native object ID.
  /// Ensures the native object is initialized before executing the action.
  @protected
  Future<T> withObjectId<T>(Future<T> Function(String objectId) action) async {
    final id = await ensureNativeObjectInitialized();

    return await action(id);
  }

  @protected
  String? get currentObjectId => objectId;
}
