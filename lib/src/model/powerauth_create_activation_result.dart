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

import 'package:flutter_powerauth_mobile_sdk_plugin/src/model/powerauth_user_info.dart';

/// Success object returned by the `createActivation` call.
class PowerAuthCreateActivationResult {

  /// Decimalized fingerprint calculated from device's and server's public keys.
  final String activationFingerprint;

  /// When available, the contents of this object depend on your enrollment server configuration.
  final Map<String, dynamic>? customAttributes;

  /// Optional information about user. The value may be null in case that feature is not supported
  /// on the server.
  final PowerAuthUserInfo? userInfo;

  PowerAuthCreateActivationResult({
    required this.activationFingerprint,
    this.customAttributes,
    this.userInfo,
  });

  factory PowerAuthCreateActivationResult.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthCreateActivationResult(
      activationFingerprint: map['activationFingerprint'] as String,
      customAttributes:
          map['customAttributes'] != null
              ? Map<String, dynamic>.from(map['customAttributes'] as Map)
              : null,
      userInfo: 
          map['userInfoClaims'] != null
              ? PowerAuthUserInfo(map['userInfoClaims'] as Map)
              : null,
    );
  }
}
