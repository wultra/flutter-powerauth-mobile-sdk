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

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'powerauth_native_object_register_method_channel.dart';

/// Platform interface for PowerAuth utility functions.
abstract class NativeObjectRegisterPlatform extends PlatformInterface {
  NativeObjectRegisterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeObjectRegisterPlatform _instance = NativeObjectRegisterMethodChannel();

  static NativeObjectRegisterPlatform get instance => _instance;

  static set instance(NativeObjectRegisterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<NativeObjectInfo>> debugDump(String? instanceId) {
    throw UnimplementedError('debugDump() has not been implemented.');
  }
}

class NativeObjectInfo {
  final String id;
  final String className;
  final String? tag;
  final bool isValid;
  final List<String> policies;
  final int createDate;
  final int? lastUseDate;
  final int? usageCount;

  NativeObjectInfo({
    required this.id,
    required this.className,
    this.tag,
    required this.isValid,
    required this.policies,
    required this.createDate,
    this.lastUseDate,
    this.usageCount,
  });

  factory NativeObjectInfo.fromMap(Map map) {
    return NativeObjectInfo(
      id: map['id'] as String,
      className: map['class'] as String,
      tag: map['tag'] as String?,
      isValid: map['isValid'] as bool,
      policies: List<String>.from(map['policies'] as List<dynamic>),
      createDate: map['createDate'] as int,
      lastUseDate: map['lastUseDate'] as int?,
      usageCount: map['usageCount'] as int?,
    );
  }

}