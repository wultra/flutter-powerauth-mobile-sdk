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

/// ### iOS specific
///
/// Class that represents the activation data sharing settings.
class PowerAuthSharingConfiguration {
  /// Name of the Apple App Group shared by the participating applications and
  /// extensions. The SDK uses it for shared `UserDefaults` and cross-process
  /// activation-state coordination.
  ///
  /// With the default shared-memory identifier, the UTF-8 representation of
  /// this string must not exceed 26 bytes. A shorter custom
  /// [sharedMemoryIdentifier] can accommodate a slightly longer app-group name.
  final String appGroup;

  /// Unique application identifier. This identifier helps you to determine which application
  /// currently holds the lock on activation data in a special operations.
  ///
  /// The length of identifier cannot exceed 127 bytes if represented as UTF-8 string. It's recommended
  /// to use application's main bundle identifier, but in general, it's up to you how you identify your
  /// own applications.
  final String appIdentifier;

  /// Apple Keychain Sharing access group used by the participating
  /// applications and extensions to access the same PowerAuth activation data.
  final String keychainAccessGroup;

  /// Optional identifier of memory shared between applications in the app
  /// group. If omitted, the native PowerAuth SDK derives an identifier from
  /// the `PowerAuth` instance identifier.
  ///
  /// An explicit value must contain 1 to 4 UTF-8 bytes and may contain only
  /// ASCII letters, digits, `+`, and `-`. A custom value is generally
  /// unnecessary and should be used only to avoid a shared-memory name
  /// collision or accommodate a longer app-group name. All participating
  /// applications and extensions must use the same effective value.
  final String? sharedMemoryIdentifier;

  PowerAuthSharingConfiguration({
    required this.appGroup,
    required this.appIdentifier,
    required this.keychainAccessGroup,
    this.sharedMemoryIdentifier,
  });

  Map<String, dynamic> toMap() {
    return {
      'appGroup': appGroup,
      'appIdentifier': appIdentifier,
      'keychainAccessGroup': keychainAccessGroup,
      'sharedMemoryIdentifier': sharedMemoryIdentifier,
    };
  }

  factory PowerAuthSharingConfiguration.fromMap(Map<String, dynamic> map) {
    return PowerAuthSharingConfiguration(
      appGroup: map['appGroup'] as String,
      appIdentifier: map['appIdentifier'] as String,
      keychainAccessGroup: map['keychainAccessGroup'] as String,
      sharedMemoryIdentifier: map['sharedMemoryIdentifier'] as String?,
    );
  }
}
