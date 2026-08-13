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

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates address from method-channel map', () {
    final addressClaims = <Object?, Object?>{
      'formatted': 'Street 1, Prague, Czech Republic',
      'street_address': 'Street 1',
      'locality': 'Prague',
      'region': 'Prague',
      'postal_code': '10000',
      'country': 'Czech Republic',
    };
    final userInfo = PowerAuthUserInfo(<Object?, Object?>{
      'sub': 'test-user',
      'address': addressClaims,
    });

    expect(userInfo.userAddress, isNotNull);
    expect(userInfo.userAddress?.formatted, addressClaims['formatted']);
    expect(userInfo.userAddress?.street, addressClaims['street_address']);
    expect(userInfo.userAddress?.locality, addressClaims['locality']);
    expect(userInfo.userAddress?.region, addressClaims['region']);
    expect(userInfo.userAddress?.postalCode, addressClaims['postal_code']);
    expect(userInfo.userAddress?.country, addressClaims['country']);
  });
}
