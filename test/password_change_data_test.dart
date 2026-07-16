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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _PasswordChangePlatform extends PowerAuthPlatform {
  int releaseCount = 0;
  String? finishedObjectId;
  String? finishedInstanceId;
  bool failFinish = false;

  @override
  Future<String> beginPasswordChange(
    String instanceId,
    PowerAuthPassword oldPassword,
  ) async => 'password-change-data';

  @override
  Future<void> finishPasswordChange(
    String instanceId,
    PowerAuthPassword newPassword,
    String passwordChangeData,
  ) async {
    finishedInstanceId = instanceId;
    finishedObjectId = passwordChangeData;
    if (failFinish) {
      throw PowerAuthException(code: PowerAuthErrorCode.authenticationError);
    }
  }

  @override
  Future<void> releasePasswordChangeData(String objectId) async {
    expect(objectId, 'password-change-data');
    releaseCount++;
  }
}

void main() {
  late PowerAuthPlatform originalPlatform;
  late _PasswordChangePlatform platform;

  setUp(() {
    originalPlatform = PowerAuthPlatform.instance;
    platform = _PasswordChangePlatform();
    PowerAuthPlatform.instance = platform;
  });

  tearDown(() {
    PowerAuthPlatform.instance = originalPlatform;
  });

  test('finish consumes and releases password change data', () async {
    final powerAuth = PowerAuth('test-instance');
    final oldPassword = PowerAuthPassword();
    final newPassword = PowerAuthPassword();
    final changeData = await powerAuth.beginPasswordChange(oldPassword);

    await powerAuth.finishPasswordChange(newPassword, changeData);
    expect(platform.finishedInstanceId, 'test-instance');
    expect(platform.finishedObjectId, 'password-change-data');
    expect(platform.releaseCount, 1);

    await changeData.release();
    expect(platform.releaseCount, 1);
  });

  test('finish failure still releases password change data', () async {
    final powerAuth = PowerAuth('test-instance');
    final changeData = await powerAuth.beginPasswordChange(PowerAuthPassword());
    platform.failFinish = true;

    await expectLater(
      powerAuth.finishPasswordChange(PowerAuthPassword(), changeData),
      throwsA(
        isA<PowerAuthException>().having(
          (e) => e.code,
          'code',
          PowerAuthErrorCode.authenticationError,
        ),
      ),
    );
    expect(platform.releaseCount, 1);
  });

  test('abandoned password change data can be released', () async {
    final powerAuth = PowerAuth('test-instance');
    final changeData = await powerAuth.beginPasswordChange(PowerAuthPassword());
    await changeData.release();
    expect(platform.releaseCount, 1);

    await changeData.release();
    expect(platform.releaseCount, 1);
  });
}
