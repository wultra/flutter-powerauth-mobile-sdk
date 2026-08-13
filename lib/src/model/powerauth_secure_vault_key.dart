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

import 'dart:typed_data';

import 'native_object_handle.dart';
import '../powerauth/powerauth_platform_interface.dart';

/// Identifies a base key available from the protocol 4.0 Secure Vault.
enum PowerAuthSecureVaultKeyId {
  /// Available after successful possession and knowledge authentication.
  knowledge,

  /// Available after any successful two-factor authentication.
  knowledgeOrBiometry,
}

/// A protocol 4.0 Secure Vault key that can derive purpose-specific keys.
///
/// The base key remains on the native side. Call [release] as soon as all
/// required keys have been derived.
class PowerAuthSecureVaultKey {
  static PowerAuthPlatform get _platform => PowerAuthPlatform.instance;
  final NativeObjectHandle _handle;

  /// Identifier of this Secure Vault key.
  final PowerAuthSecureVaultKeyId keyIdentifier;

  /// Creates a wrapper for an already fetched native Secure Vault key.
  PowerAuthSecureVaultKey.fromNative({
    required this.keyIdentifier,
    required String objectId,
  }) : _handle = NativeObjectHandle.fromNative(objectId);

  /// Derives a key and returns it as raw bytes.
  ///
  /// [index] identifies the derived key and [keySize] specifies its size in
  /// bytes. The minimum supported key size is 16 bytes.
  Future<Uint8List> deriveKey(int index, int keySize) => _handle.withObjectId(
    (objectId) => _platform.deriveSecureVaultKey(objectId, index, keySize),
  );

  /// Releases the underlying native Secure Vault key.
  Future<void> release() => _handle.release();
}
