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
import '../utils/activation_credentials.dart';
import '../utils/integration_helper.dart';

import 'package:flutter_test/flutter_test.dart';

main() {
  group('Token tests', () {
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

    test('testTokenManagement', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      final t1 = 'possessionToken';
      final t1Cred = credentials.possession();
      t1Invcred() async {
        return await credentials.knowledge();
      }

      final t2 = 'knowledgeToken';
      t2Cred() async {
        return await credentials.knowledge();
      }

      final t2Invcred = credentials.possession();

      final tokenStore = sdk.tokenStore;

      expect(await tokenStore.hasLocalToken(t1), false);
      expect(await tokenStore.hasLocalToken(t2), false);

      expect(
        () async => await tokenStore.generateHeaderForToken(t1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.cannotGenerateToken,
          ),
        ),
      );
      expect(
        () async => await tokenStore.generateHeaderForToken(t2),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.cannotGenerateToken,
          ),
        ),
      );
      expect(
        () async => await tokenStore.getLocalToken(t1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.localTokenNotAvailable,
          ),
        ),
      );
      expect(
        () async => await tokenStore.getLocalToken(t2),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.localTokenNotAvailable,
          ),
        ),
      );

      final token1 = await tokenStore.requestAccessToken(t1, t1Cred);
      expect(token1.tokenIdentifier, isNotNull);
      expect(token1.tokenName, t1);

      final token2 = await tokenStore.requestAccessToken(t2, await t2Cred());
      expect(token2.tokenIdentifier, isNotNull);
      expect(token2.tokenName, t2);

      expect(await tokenStore.hasLocalToken(t1), true);
      expect(await tokenStore.hasLocalToken(t2), true);
      expect(await tokenStore.getLocalToken(t1), isNotNull);
      expect(await tokenStore.getLocalToken(t2), isNotNull);

      final token1a = await tokenStore.requestAccessToken(t1, t1Cred);
      expect(token1a.tokenIdentifier, token1.tokenIdentifier);
      expect(token1a.tokenName, t1);
      final token2a = await tokenStore.requestAccessToken(t2, await t2Cred());
      expect(token2a.tokenIdentifier, token2.tokenIdentifier);
      expect(token2a.tokenName, t2);

      final token1b = await tokenStore.getLocalToken(t1);
      expect(token1b.tokenIdentifier, token1.tokenIdentifier);
      expect(token1b.tokenName, t1);
      final token2b = await tokenStore.getLocalToken(t2);
      expect(token2b.tokenIdentifier, token2.tokenIdentifier);
      expect(token2b.tokenName, t2);
      await expectLater(
        tokenStore.requestAccessToken(t1, await t1Invcred()),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      await expectLater(
        tokenStore.requestAccessToken(t2, t2Invcred),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.wrongParameter,
          ),
        ),
      );
      expect(tokenStore.generateHeaderForToken(t1), completes);
      expect(tokenStore.generateHeaderForToken(t2), completes);
      expect(tokenStore.removeLocalToken(t1), completes);
      expect(await tokenStore.hasLocalToken(t1), false);
      expect(
        tokenStore.generateHeaderForToken(t1),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.cannotGenerateToken,
          ),
        ),
      );
      await expectLater(tokenStore.removeAccessToken(t2), completes);

      final hasToken = await tokenStore.hasLocalToken(t2);
      expect(hasToken, isFalse);

      await expectLater(
        tokenStore.generateHeaderForToken(t2),
        throwsA(
          isA<PowerAuthException>().having(
            (e) => e.code,
            "code",
            PowerAuthErrorCode.cannotGenerateToken,
          ),
        ),
      );
    });

    test('testTokenCalculation', () async {
      await helper.prepareActiveActivation(
        await credentials.validPasswordObject(),
      );

      final t1 = 'possessionToken';
      final t1Cred = credentials.possession();
      final t2 = 'knowledgeToken';
      t2Cred() async {
        return await credentials.knowledge();
      }

      final activationId = await sdk.getActivationIdentifier();

      final tokenStore = sdk.tokenStore;

      final token1 = await tokenStore.requestAccessToken(t1, t1Cred);
      expect(token1.tokenIdentifier, isNotNull);
      expect(token1.tokenName, t1);

      final token2 = await tokenStore.requestAccessToken(t2, await t2Cred());
      expect(token2.tokenIdentifier, isNotNull);
      expect(token2.tokenName, t2);

      await sdk.timeSynchronizationService.resetTimeSynchronization(); // force time sync

      final header1 = await tokenStore.generateHeaderForToken(t1);
      expect(header1.value, isNotNull);
      final result1 = await helper.verifyToken(header1.value);
      expect(result1.tokenValid, true);
      expect(result1.registrationId, activationId);
      expect(result1.signatureType, 'POSSESSION');

      final header2 = await tokenStore.generateHeaderForToken(t2);
      expect(header2.value, isNotNull);
      final result2 = await helper.verifyToken(header2.value);
      expect(result2.tokenValid, true);
      expect(result2.registrationId, activationId);
      expect(result2.signatureType, 'POSSESSION_KNOWLEDGE');
    });
  });
}
