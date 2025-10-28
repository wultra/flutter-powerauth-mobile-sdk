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

import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'powerauth_crypto_utils_method_channel.dart';

/// Platform interface for PowerAuth core cryptographic utilities.
abstract class PowerAuthCryptoUtilsPlatform extends PlatformInterface {

  PowerAuthCryptoUtilsPlatform() : super(token: _token);

  static final Object _token = Object();

  static PowerAuthCryptoUtilsPlatform _instance = PowerAuthCryptoUtilsMethodChannel();

  static PowerAuthCryptoUtilsPlatform get instance => _instance;

  static set instance(PowerAuthCryptoUtilsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Generate cryptographically secure random bytes of given [length].
  Future<Uint8List> randomBytes(int length) {
    throw UnimplementedError('randomBytes() has not been implemented.');
  }

  /// Compute SHA-256 hash of input [data].
  Future<Uint8List> hashSha256(Uint8List data) {
    throw UnimplementedError('hashSha256() has not been implemented.');
  }
}
