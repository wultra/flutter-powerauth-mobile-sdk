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

import 'powerauth_native_object_register_platform_interface.dart';

/// The Register class extends `NativeObjectRegister` functionality for this test suite purposes.
/// 
/// ### Warning
/// 
/// > You suppose do not replicate such functionality in your application's code, because it will not
/// > work in the release build.
class NativeObjectRegister {

  NativeObjectRegister._();

  static NativeObjectRegisterPlatform get _platform => NativeObjectRegisterPlatform.instance;

  static Future<bool> isValidNativeObject(String objectId) async {
    return await _platform.isValidNativeObject(objectId);
  }

  static Future<ObjectsCount> countObjects(String tag) async {
    final r = await _platform.debugDump(tag);
    final valid = r.where((x) => x.isValid).length;
    return ObjectsCount(
      valid: valid, 
      invalid: r.length - valid
    );
  }

  static Future<String> createObject(NativeObjectCmdData data) async {
    return await _platform.debugCommand(NativeObjectCmd.create, data);
  }

  static Future<bool> findObject(String objectId, NativeObjectType type) async {
    return await _platform.debugCommand(NativeObjectCmd.find, NativeObjectCmdData(objectId: objectId, objectType: type)) as bool;
  }

  static Future<bool> useObject(String objectId, NativeObjectType type) async {
    return await _platform.debugCommand(NativeObjectCmd.use, NativeObjectCmdData(objectId: objectId, objectType: type)) as bool;
  }

  static Future<bool> touchObject(String objectId, NativeObjectType type) async {
    return await _platform.debugCommand(NativeObjectCmd.touch, NativeObjectCmdData(objectId: objectId, objectType: type)) as bool;
  }

  static Future<bool> removeObject(String objectId, NativeObjectType type) async {
    return await _platform.debugCommand(NativeObjectCmd.release, NativeObjectCmdData(objectId: objectId, objectType: type)) as bool;
  }

  static Future<List<NativeObjectInfo>> debugDump(String? instanceId) => _platform.debugDump(instanceId);
}

class ObjectsCount {
  final int valid;
  final int invalid;

  get total => valid + invalid;

  ObjectsCount({
    required this.valid,
    required this.invalid,
  });
}

/// Type of native object.
enum NativeObjectType {
  data,
  secureData,
  number,
  password,
}

/// Data accepted in debugCommand() function.
class NativeObjectCmdData {
  final String? objectId; // object id, accepted in 'release', 'use', 'find', 'touch'
  final String? objectTag; // object tag, accepted in 'create', 'releaseAll'
  final NativeObjectType? objectType; // object type accepted in 'create', 'release', 'use', 'find', 'touch'
  final List<String>? releasePolicy; // use 'manual', 'after_use N', 'keep_alive T', 'expire T', accepted in 'create'
  final int? cleanupPeriod; // cleanup period in milliseconds <100, 60000>, accepted in 'setPeriod'

  NativeObjectCmdData({
    this.objectId,
    this.objectTag,
    this.objectType,
    this.releasePolicy,
    this.cleanupPeriod,
  });

  factory NativeObjectCmdData.fromMap(Map map) {
    return NativeObjectCmdData(
      objectId: map['objectId'] as String?,
      objectTag: map['objectTag'] as String?,
      objectType: map['objectType'] != null
          ? NativeObjectType.values.firstWhere(
              (e) => e.name == map['objectType'],
              orElse: () => NativeObjectType.data,
            )
          : null,
      releasePolicy: map['releasePolicy'] != null
          ? List<String>.from(map['releasePolicy'] as List)
          : null,
      cleanupPeriod: map['cleanupPeriod'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'objectId': objectId,
      'objectTag': objectTag,
      'objectType': objectType?.name,
      'releasePolicy': releasePolicy,
      'cleanupPeriod': cleanupPeriod,
    };
  }
}
