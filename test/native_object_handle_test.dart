/*
 * Copyright 2026 Wultra s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:async';

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/native_object_handle.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_error.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _NativeObjectRegisterPlatform extends NativeObjectRegisterPlatform {
  final releasedObjectIds = <String>[];

  @override
  Future<void> releaseNativeObject(String objectId) async {
    releasedObjectIds.add(objectId);
  }
}

void main() {
  late NativeObjectRegisterPlatform originalPlatform;
  late _NativeObjectRegisterPlatform platform;

  setUp(() {
    originalPlatform = NativeObjectRegisterPlatform.instance;
    platform = _NativeObjectRegisterPlatform();
    NativeObjectRegisterPlatform.instance = platform;
  });

  tearDown(() {
    NativeObjectRegisterPlatform.instance = originalPlatform;
  });

  test('release before lazy initialization is a reusable no-op', () async {
    var initializationCount = 0;
    final handle = NativeObjectHandle.lazy(() async {
      initializationCount++;
      return 'lazy-object';
    });

    await handle.release();

    expect(initializationCount, 0);
    expect(platform.releasedObjectIds, isEmpty);
    expect(await handle.getObjectId(), 'lazy-object');
    expect(initializationCount, 1);

    await handle.release();
    await handle.release();

    expect(platform.releasedObjectIds, ['lazy-object']);
    await expectLater(
      handle.getObjectId(),
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.invalidNativeObject,
        ),
      ),
    );
  });

  test('release during initialization releases the eventual object', () async {
    final initializationStarted = Completer<void>();
    final initialization = Completer<String>();
    final handle = NativeObjectHandle.lazy(() {
      initializationStarted.complete();
      return initialization.future;
    });

    final objectId = handle.getObjectId();
    await initializationStarted.future;
    final release = handle.release();
    initialization.complete('pending-object');

    await expectLater(
      objectId,
      throwsA(
        isA<PowerAuthException>().having(
          (error) => error.code,
          'code',
          PowerAuthErrorCode.invalidNativeObject,
        ),
      ),
    );
    await release;

    expect(platform.releasedObjectIds, ['pending-object']);
  });

  test('concurrent access performs one initialization', () async {
    final initialization = Completer<String>();
    var initializationCount = 0;
    final handle = NativeObjectHandle.lazy(() {
      initializationCount++;
      return initialization.future;
    });

    final first = handle.getObjectId();
    final second = handle.getObjectId();
    initialization.complete('shared-object');

    expect(await Future.wait([first, second]), ['shared-object', 'shared-object']);
    expect(initializationCount, 1);
  });

  test('failed initialization is retried without retaining partial state', () async {
    var initializationCount = 0;
    final handle = NativeObjectHandle.lazy(() async {
      initializationCount++;
      if (initializationCount == 1) {
        throw StateError('first initialization failed');
      }
      return 'recovered-object';
    });

    await expectLater(handle.getObjectId(), throwsStateError);
    expect(await handle.getObjectId(), 'recovered-object');
    expect(initializationCount, 2);

    await handle.release();
    expect(platform.releasedObjectIds, ['recovered-object']);
  });
}
