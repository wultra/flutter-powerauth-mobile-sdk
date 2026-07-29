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
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

enum UserPromptDuration { quick, normal }

Uint8List utf8Bytes(String value) => Uint8List.fromList(utf8.encode(value));

Matcher throwsPowerAuthCode(PowerAuthErrorCode code) {
  return throwsA(
    isA<PowerAuthException>().having((error) => error.code, 'code', code),
  );
}

Matcher throwsPowerAuthServerError(PowerAuthErrorCode code) {
  return throwsA(
    isA<PowerAuthException>()
        .having((error) => error.code, 'code', code)
        .having(
          (error) => error.errorData,
          'errorData',
          allOf(
            isNotNull,
            contains('httpStatusCode'),
            contains('responseBody'),
          ),
        ),
  );
}

PowerAuthErrorCode platformErrorCode({
  required PowerAuthErrorCode android,
  required PowerAuthErrorCode ios,
}) => Platform.isAndroid ? android : ios;

Future<void> sleep(int milliseconds) async {
  await Future.delayed(Duration(milliseconds: milliseconds));
}

Future<List<NativeObjectInfo>> waitForNativeObjects({
  String? instanceId,
  required bool Function(List<NativeObjectInfo> objects) predicate,
  Duration timeout = const Duration(seconds: 3),
  Duration pollInterval = const Duration(milliseconds: 25),
}) async {
  final deadline = DateTime.now().add(timeout);
  var objects = await NativeObjectRegister.debugDump(instanceId);
  while (!predicate(objects) && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(pollInterval);
    objects = await NativeObjectRegister.debugDump(instanceId);
  }
  if (!predicate(objects)) {
    fail(
      'Native-object registry did not reach the expected state within '
      '${timeout.inMilliseconds} ms. Observed: '
      '${objects.map((object) => {'id': object.id, 'class': object.className, 'tag': object.tag, 'valid': object.isValid, 'policies': object.policies}).toList()}',
    );
  }
  return objects;
}

Future<NativeObjectInfo> waitForNewNativeObject({
  required String instanceId,
  required Set<String> previousIds,
  required bool Function(NativeObjectInfo object) matches,
}) async {
  final objects = await waitForNativeObjects(
    instanceId: instanceId,
    predicate:
        (items) =>
            items
                .where(
                  (item) => !previousIds.contains(item.id) && matches(item),
                )
                .length ==
            1,
  );
  return objects.singleWhere(
    (item) => !previousIds.contains(item.id) && matches(item),
  );
}

Future<void> showPrompt(
  String text, {
  UserPromptDuration duration = UserPromptDuration.normal,
}) async {
  // TODO: this should be displayed in the UI
  print(text);
}
