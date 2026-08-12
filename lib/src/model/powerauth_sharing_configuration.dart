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
/// Configuration for sharing activation data between iOS applications and
/// extensions.
///
/// All participants must use the same `PowerAuth` instance identifier,
/// [appGroup], [keychainAccessGroup], and effective [sharedMemoryIdentifier].
/// Each participant must use a different [appIdentifier].
class PowerAuthSharingConfiguration {
  /// Name of the Apple App Group shared by the participating applications and
  /// extensions. The SDK uses it for shared `UserDefaults` and cross-process
  /// activation-state coordination.
  ///
  /// Use the same value in every participating target and include it in each
  /// target's App Groups entitlement.
  ///
  /// The value must not be empty.
  ///
  /// The app group, a period, and the effective shared-memory identifier must
  /// fit in 31 UTF-8 bytes. With the default four-byte identifier, this value
  /// therefore must not exceed 26 bytes. A shorter custom
  /// [sharedMemoryIdentifier] can accommodate a slightly longer app-group name.
  final String appGroup;

  /// Identifier unique to this participating application or extension. This
  /// identifies the application that currently holds the lock for an exclusive
  /// operation.
  ///
  /// The value must not be empty or exceed 127 UTF-8 bytes. Using the
  /// application's main bundle identifier is recommended.
  final String appIdentifier;

  /// Apple Keychain Sharing access group used by the participating
  /// applications and extensions to access the same PowerAuth activation data.
  /// Use the same fully qualified value in every target and include it in each
  /// target's Keychain Sharing entitlement.
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
  /// After configuration, the asynchronous `PowerAuth.sharingConfiguration`
  /// getter contains the effective generated value even if the input omitted
  /// this property.
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
