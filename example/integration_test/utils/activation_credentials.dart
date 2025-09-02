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

import 'dart:math';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

class ActivationCredentials {
  late String validPassword;
  late String invalidPassword;

  ActivationCredentials() {
    const available = [
      'VerySecure',
      '1234',
      'nbusr123',
      '39h132v,kJdfvAl',
      '98765',
      'correct horse battery staple',
    ];
    final idx = Random().nextInt(available.length);
    validPassword = available[idx];
    invalidPassword = available[(idx + 1) % available.length];
  }

  PowerAuthAuthentication possession() => PowerAuthAuthentication.possession();

  PowerAuthAuthentication biometry() => PowerAuthAuthentication.biometry(
    biometricPrompt: PowerAuthBiometricPrompt(
      promptTitle: 'Authenticate',
      promptMessage: 'Please authenticate with biometry',
    ),
  );

  Future<PowerAuthAuthentication> knowledge() async =>
      PowerAuthAuthentication.password(await validPasswordObject());
  Future<PowerAuthAuthentication> invalidKnowledge() async =>
      PowerAuthAuthentication.password(await invalidPasswordObject());

  Future<PowerAuthPassword> validPasswordObject({bool destroyOnUse = true}) =>
      PowerAuthPassword.fromString(validPassword, destroyOnUse: destroyOnUse);
  Future<PowerAuthPassword> invalidPasswordObject({bool destroyOnUse = true}) =>
      PowerAuthPassword.fromString(invalidPassword, destroyOnUse: destroyOnUse);
}
