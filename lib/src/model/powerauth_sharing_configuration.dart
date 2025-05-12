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

  /// Name of app group that allows you sharing data between multiple applications. Be aware that the value
  /// overrides [accessGroupName] property if it's provided in [PowerAuthKeychainConfiguration].
  ///
  /// The UTF-8 representation of this string should not exceed 26 bytes, due to internal limitations applied
  /// on the operating system level.
  final String appGroup;

  /// Unique application identifier. This identifier helps you to determine which application
  /// currently holds the lock on activation data in a special operations.
  ///
  /// The length of identifier cannot exceed 127 bytes if represented as UTF-8 string. It's recommended
  /// to use application's main bundle identifier, but in general, it's up to you how you identify your
  /// own applications.
  final String appIdentifier;

  /// Keychain access group name used by the PowerAuthSDK keychain instances.
  final String keychainAccessGroup;

  /// Optional identifier of memory shared between the applications in app group. If identifier is not provided
  /// then PowerAuthSDK calculate unique identifier based on [PowerAuth.instanceId].
  ///
  /// You can set this property in case that PowerAuth SDK generates identifier that collide with your application's
  /// functionality. The configuration of PowerAuthSDK instance always contains an actual identifier used for its
  /// shared memory initialization, so you can test whether the generated identifier is OK.
  ///
  /// The length of identifier cannot exceed 4 bytes if represented as UTF8 string. This is an operating system
  /// limitation.
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
}
