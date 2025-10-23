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
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/method_channel_helper.dart';
import 'powerauth_crypto_utils_platform_interface.dart';

/// Method channel implementation for PowerAuth core cryptographic utilities.
class PowerAuthCryptoUtilsMethodChannel extends PowerAuthCryptoUtilsPlatform
    with MethodChannelHelper {

  @override
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('powerauth_plugin');

  @override
  Future<Uint8List> randomBytes(int length) async {
    final result = await invokeMethod<dynamic>('cryptoUtils_randomBytes', {
      'length': length
    });

    if (result is Uint8List) {
      return result;
    } else {
      throw PlatformException(
        code: 'unexpectedResult',
        message: 'Unexpected result type from randomBytes: ${result.runtimeType}',
      );
    }
  }

  @override
  Future<Uint8List> hashSha256(Uint8List data) async {
    final result = await invokeMethod<Uint8List>('cryptoUtils_hashSha256', {
      'data': data,
    });
    return result;
  }
}
