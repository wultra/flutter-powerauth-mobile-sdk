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

import 'powerauth_crypto_utils_platform_interface.dart';

/// Provides core cryptographic utilities based on PowerAuthCore.
class PowerAuthCryptoUtils {
  PowerAuthCryptoUtils._();

  static PowerAuthCryptoUtilsPlatform get _platform => PowerAuthCryptoUtilsPlatform.instance;

  /// Generate cryptographically secure random bytes of given [length].
  static Future<Uint8List> randomBytes(int length) => _platform.randomBytes(length);

  /// Compute SHA-256 hash for the provided [data].
  static Future<Uint8List> hashSha256(Uint8List data) => _platform.hashSha256(data);
}
