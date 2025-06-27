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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

class InternalAuth implements PowerAuthAuthentication {
  
  /// Password used for the knowledge factor.
  /// Set only if the knowledge factor is required.
  @override
  final PowerAuthPassword? password;

  /// Configuration for the biometric prompt, if biometry factor is used.
  @override
  final PowerAuthBiometricPrompt? biometricPrompt;

  /// Indicates that this authentication object is intended for persisting an activation.
  final bool forActivationPersist;

  /// Indicates if the biometry factor should be used.
  final bool useBiometry;

  /// Indicate that this object has reusable biometry.
  bool isReusable = false;

  /// Contains identifier for data object containing biometry key, allocated in the native code.
  String? biometryKeyId;

  InternalAuth({
    this.password,
    this.biometricPrompt,
    required this.forActivationPersist,
  }) : useBiometry = biometricPrompt != null;

  @override
  Future<Map<String, dynamic>> prepareAuthArguments(Map<String, dynamic> baseArgs) async {
    
    final args = Map<String, dynamic>.from(baseArgs);
    final rawPassword = await password?.toRawPasswordMap();

    final authMap = {
      'password': rawPassword,
      'biometricPrompt': biometricPrompt?.toMap(),
      'isPersist': forActivationPersist,
      'isBiometry': useBiometry,
      'isReusable': isReusable,
      'biometryKeyId': biometryKeyId,
    }..removeWhere((key, value) => value == null);

    args['authentication'] = authMap;
    return args;
  }
}