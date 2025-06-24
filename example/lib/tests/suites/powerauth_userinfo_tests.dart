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
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

class PowerAuthUserInfoTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testEmptyObjectCreation,
    testStandardClaims,
    testUserInfoIntegration
  ];

  Future<void> testEmptyObjectCreation() async {
    final info = PowerAuthUserInfo(null);
    await expect(info.subject).toBeNull();
    await expect(info.name).toBeNull();
    await expect(info.givenName).toBeNull();
    await expect(info.middleName).toBeNull();
    await expect(info.familyName).toBeNull();
    await expect(info.nickname).toBeNull();
    await expect(info.preferredUsername).toBeNull();
    await expect(info.profileUrl).toBeNull();
    await expect(info.pictureUrl).toBeNull();
    await expect(info.websiteUrl).toBeNull();
    await expect(info.email).toBeNull();
    await expect(info.isEmailVerified).toBe(false);
    await expect(info.phoneNumber).toBeNull();
    await expect(info.isPhoneNumberVerified).toBe(false);
    await expect(info.gender).toBeNull();
    await expect(info.zoneInfo).toBeNull();
    await expect(info.locale).toBeNull();
    await expect(info.userAddress).toBeNull();
    await expect(info.allClaims['custom_claim']).toBeNull();
  }

  Future<void> testStandardClaims() async {
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

    await expect(info.subject).toBe("123456");
    await expect(info.name).toBe("John Jacob Doe");
    await expect(info.givenName).toBe("John");
    await expect(info.middleName).toBe("Jacob");
    await expect(info.familyName).toBe("Doe");
    await expect(info.nickname).toBe("jjd");
    await expect(info.preferredUsername).toBe("JacobTheGreat");
    await expect(info.profileUrl).toBe("https://jjd.com/profile");
    await expect(info.pictureUrl).toBe("https://jjd.com/avatar.jpg");
    await expect(info.websiteUrl).toBe("https://jjd.com");
    await expect(info.email).toBe("jacob@jjd.com");
    await expect(info.isEmailVerified).toBe(true);
    await expect(info.phoneNumber).toBe("+1 (425) 555-1212");
    await expect(info.isPhoneNumberVerified).toBe(true);
    await expect(info.gender).toBe("male");
    await expect(info.zoneInfo).toBe("Europe/Prague");
    await expect(info.locale).toBe("en-US");
    await expect(info.updatedAt!.millisecondsSinceEpoch ~/ 1000).toBe(updatedAt);

    // Address
    final address = info.userAddress;
    await expect(address).toBeDefined();
    await expect(address?.formatted).toBe("Belehradska 858/23\n120 00 Prague - Vinohrady\nCzech Republic");
    await expect(address?.street).toBe("Belehradska 858/23\nVinohrady");
    await expect(address?.locality).toBe("Prague");
    await expect(address?.region).toBe("Prague");
    await expect(address?.postalCode).toBe("12000");
    await expect(address?.country).toBe("Czech Republic");

    await expect(info.allClaims['custom_claim']).toBe("Hello world!");

    // Birthdate
    final birthdate = info.birthdate;
    await expect(birthdate?.year).toBe(1984);
    await expect(birthdate?.month).toBe(2);
    await expect(birthdate?.day).toBe(21);

    // Test false booleans
    final jsonString2 = '''
    {
      "email_verified": false,
      "phone_number_verified": false
    }
    ''';
    final json2 = jsonDecode(jsonString2) as Map<String, dynamic>;
    final info2 = PowerAuthUserInfo(json2);
    await expect(info2.isPhoneNumberVerified).toBe(false);
    await expect(info2.isEmailVerified).toBe(false);
  }

  Future<void> testUserInfoIntegration() async {

    final userID = IntegrationHelper.randomString(20);
    final createdActivation = await helper.createActivation(userId: userID);
    final result = await sdk.createActivation(PowerAuthActivation.fromActivationCode(activationCode: createdActivation.activationCode, name: "Flutter Tests"));
    await sdk.persistActivation(PowerAuthAuthentication.persistWithPassword(await credentials.validPasswordObject()));
    final userInfo = result.userInfo;
    await expect(userInfo).toBeDefined();
    await expect(sdk.getLastFetchedUserInfo()).toBeDefined();
    await expect(userInfo?.subject).toBe(userID);
    await expect((await sdk.getLastFetchedUserInfo())?.subject).toBe(userID);

    final fetchedUserInfo = await sdk.fetchUserInfo();
    await expect(fetchedUserInfo).toBeDefined();
    await expect(fetchedUserInfo.subject).toBe(userID);
    await expect(fetchedUserInfo.subject).toBe(userInfo?.subject);
  }
}