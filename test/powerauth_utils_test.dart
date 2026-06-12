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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

PowerAuthSharingConfiguration _sharing(String appGroup) {
  return PowerAuthSharingConfiguration(
    appGroup: appGroup,
    appIdentifier: 'com.wultra.test',
    keychainAccessGroup: 'group.com.wultra.test',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PowerAuthUtils.migrateiOSSharingConfiguration – validation', () {
    test('throws ArgumentError when both "from" and "to" are null', () {
      expect(
        () => PowerAuthUtils.migrateiOSSharingConfiguration(),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError when both share the same appGroup', () {
      expect(
        () => PowerAuthUtils.migrateiOSSharingConfiguration(
          from: _sharing('group.same'),
          to: _sharing('group.same'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('PowerAuthUtils.migrateiOSSharingConfiguration – method channel', () {
    const channel = MethodChannel('powerauth_plugin');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('on iOS invokes util_migrateSharingConfiguration with both appGroups', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await PowerAuthUtils.migrateiOSSharingConfiguration(
        from: _sharing('group.from'),
        to: _sharing('group.to'),
      );

      expect(log, hasLength(1));
      expect(log.single.method, 'util_migrateSharingConfiguration');
      expect(log.single.arguments, {
        'fromAppGroup': 'group.from',
        'toAppGroup': 'group.to',
      });
    });

    test('on iOS passes null for the omitted side', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      await PowerAuthUtils.migrateiOSSharingConfiguration(
        to: _sharing('group.to'),
      );

      expect(log, hasLength(1));
      expect(log.single.arguments, {
        'fromAppGroup': null,
        'toAppGroup': 'group.to',
      });
    });

    test('on Android it is a no-op (no native call)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await PowerAuthUtils.migrateiOSSharingConfiguration(
        from: _sharing('group.from'),
        to: _sharing('group.to'),
      );

      expect(log, isEmpty);
    });
  });
}
