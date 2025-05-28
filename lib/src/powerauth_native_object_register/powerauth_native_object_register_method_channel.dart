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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'powerauth_native_object_register_platform_interface.dart';
import '../utils/method_channel_helper.dart';
import '../model/powerauth_activation_code.dart';
import '../model/powerauth_error.dart';
import '../powerauth_password/powerauth_password.dart';

/// Method channel implementation for PowerAuth utility functions.
class NativeObjectRegisterMethodChannel extends NativeObjectRegisterPlatform
    with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'powerauth_plugin',
  );

  @override
  Future<List<NativeObjectInfo>> debugDump(String? instanceId) async {
    final result = await invokeMethod<List<dynamic>>(
      'register_debugDump',
      {'instanceId': instanceId},
    );
    return result.map((x) => NativeObjectInfo.fromMap(x)).toList();
  }
}
