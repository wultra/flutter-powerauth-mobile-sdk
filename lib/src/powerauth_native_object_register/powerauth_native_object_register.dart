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

  
  static Future<ObjectsCount> countObjects(String tag) async {
    final r = await _platform.debugDump(tag);
    final valid = r.where((x) => x.isValid).length;
    return ObjectsCount(
      valid: valid, 
      invalid: r.length - valid
    );
  }
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