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

import 'dart:convert';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import '../utils/activation_credentials.dart';
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('User info tests', () {
    late IntegrationHelper helper;
    late PowerAuth sdk;
    late ActivationCredentials credentials;

    setUp(() async {
      sdk = PowerAuth(IntegrationHelper.randomString(30));
      helper = IntegrationHelper(sdk);
      await helper.configure();

      credentials = ActivationCredentials();
    });

    tearDown(() async {
      await helper.cleanup();
    });

    test('testEmptyObjectCreation', () async {
      final info = PowerAuthUserInfo(null);
      expect(info.subject, isNull);
      expect(info.name, isNull);
      expect(info.givenName, isNull);
      expect(info.middleName, isNull);
      expect(info.familyName, isNull);
      expect(info.nickname, isNull);
      expect(info.preferredUsername, isNull);
      expect(info.profileUrl, isNull);
      expect(info.pictureUrl, isNull);
      expect(info.websiteUrl, isNull);
      expect(info.email, isNull);
      expect(info.isEmailVerified, false);
      expect(info.phoneNumber, isNull);
      expect(info.isPhoneNumberVerified, false);
      expect(info.gender, isNull);
      expect(info.zoneInfo, isNull);
      expect(info.locale, isNull);
      expect(info.userAddress, isNull);
      expect(info.allClaims['custom_claim'], isNull);
    });

    test('testStandardClaims', () async {
      final now = DateTime.now().toUtc();
      final updatedAt = (now.millisecondsSinceEpoch / 1000).floor();

      final jsonString = '''
    {
      "sub": "123456",
      "name": "John Jacob Doe",
      "given_name": "John",
      "family_name": "Doe",
      "middle_name": "Jacob",
      "nickname": "jjd",
      "preferred_username": "JacobTheGreat",
      "profile": "https://jjd.com/profile",
      "picture": "https://jjd.com/avatar.jpg",
      "website": "https://jjd.com",
      "email": "jacob@jjd.com",
      "email_verified": true,
      "gender": "male",
      "birthdate": "1984-02-21",
      "zoneinfo": "Europe/Prague",
      "locale": "en-US",
      "phone_number": "+1 (425) 555-1212",
      "phone_number_verified": true,
      "address": {
        "formatted": "Belehradska 858/23\\r\\n120 00 Prague - Vinohrady\\r\\nCzech Republic",
        "street_address": "Belehradska 858/23\\r\\nVinohrady",
        "locality": "Prague",
        "region": "Prague",
        "postal_code": "12000",
        "country": "Czech Republic"
      },
      "updated_at": $updatedAt,
      "custom_claim": "Hello world!"
    }
    ''';

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final info = PowerAuthUserInfo(json);

      expect(info.subject, "123456");
      expect(info.name, "John Jacob Doe");
      expect(info.givenName, "John");
      expect(info.middleName, "Jacob");
      expect(info.familyName, "Doe");
      expect(info.nickname, "jjd");
      expect(info.preferredUsername, "JacobTheGreat");
      expect(info.profileUrl, "https://jjd.com/profile");
      expect(info.pictureUrl, "https://jjd.com/avatar.jpg");
      expect(info.websiteUrl, "https://jjd.com");
      expect(info.email, "jacob@jjd.com");
      expect(info.isEmailVerified, true);
      expect(info.phoneNumber, "+1 (425) 555-1212");
      expect(info.isPhoneNumberVerified, true);
      expect(info.gender, "male");
      expect(info.zoneInfo, "Europe/Prague");
      expect(info.locale, "en-US");
      expect(info.updatedAt!.millisecondsSinceEpoch ~/ 1000, updatedAt);
      final address = info.userAddress;
      expect(address, isNotNull);
      expect(
        address?.formatted,
        "Belehradska 858/23\n120 00 Prague - Vinohrady\nCzech Republic",
      );
      expect(address?.street, "Belehradska 858/23\nVinohrady");
      expect(address?.locality, "Prague");
      expect(address?.region, "Prague");
      expect(address?.postalCode, "12000");
      expect(address?.country, "Czech Republic");

      expect(info.allClaims['custom_claim'], "Hello world!");
      final birthdate = info.birthdate;
      expect(birthdate?.year, 1984);
      expect(birthdate?.month, 2);
      expect(birthdate?.day, 21);
      final jsonString2 = '''
    {
      "email_verified": false,
      "phone_number_verified": false
    }
    ''';
      final json2 = jsonDecode(jsonString2) as Map<String, dynamic>;
      final info2 = PowerAuthUserInfo(json2);
      expect(info2.isPhoneNumberVerified, false);
      expect(info2.isEmailVerified, false);
    });

    test('testUserInfoIntegration', () async {
      final userID = IntegrationHelper.randomString(20);
      final createdActivation = await helper.createActivation(userId: userID);
      final result = await sdk.createActivation(
        PowerAuthActivation.fromActivationCode(
          activationCode: createdActivation.activationCode,
          name: "Flutter Tests",
        ),
      );
      await sdk.persistActivation(
        PowerAuthAuthentication.persistWithPassword(
          await credentials.validPasswordObject(),
        ),
      );
      final userInfo = result.userInfo;
      expect(userInfo, isNotNull);
      expect(sdk.getLastFetchedUserInfo(), isNotNull);
      expect(userInfo?.subject, userID);
      expect((await sdk.getLastFetchedUserInfo())?.subject, userID);

      final fetchedUserInfo = await sdk.fetchUserInfo();
      expect(fetchedUserInfo, isNotNull);
      expect(fetchedUserInfo.subject, userID);
      expect(fetchedUserInfo.subject, userInfo?.subject);
    });
  });
}
