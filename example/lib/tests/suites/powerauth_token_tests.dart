import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/powerauth_signature_tests.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';

class PowerauthTokenTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testTokenManagement,
    testTokenCalculation
  ];

  Future<void> testTokenManagement() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    final t1 = 'possessionToken';
    final t1Cred = credentials.possession();
    t1Invcred() async { return await credentials.knowledge(); }
    final t2 = 'knowledgeToken';
    t2Cred() async { return await credentials.knowledge(); }
    final t2Invcred = credentials.possession();

    final tokenStore = sdk.tokenStore;

    await expect(tokenStore.hasLocalToken(t1)).toBe(false);
    await expect(tokenStore.hasLocalToken(t2)).toBe(false);

    await expect(tokenStore.generateHeaderForToken(t1)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);
    await expect(tokenStore.generateHeaderForToken(t2)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);
    await expect(tokenStore.getLocalToken(t1)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);
    await expect(tokenStore.getLocalToken(t2)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);

    final token1 = await tokenStore.requestAccessToken(t1, t1Cred);
    await expect(token1.tokenIdentifier).toBeDefined();
    await expect(token1.tokenName).toBe(t1);

    final token2 = await tokenStore.requestAccessToken(t2, await t2Cred());
    await expect(token2.tokenIdentifier).toBeDefined();
    await expect(token2.tokenName).toBe(t2);

    await expect(tokenStore.hasLocalToken(t1)).toBe(true);
    await expect(tokenStore.hasLocalToken(t2)).toBe(true);
    await expect(tokenStore.getLocalToken(t1)).toBeDefined();
    await expect(tokenStore.getLocalToken(t2)).toBeDefined();

    final token1a = await tokenStore.requestAccessToken(t1, t1Cred);
    await expect(token1a.tokenIdentifier).toBe(token1.tokenIdentifier);
    await expect(token1a.tokenName).toBe(t1);
    final token2a = await tokenStore.requestAccessToken(t2, await t2Cred());
    await expect(token2a.tokenIdentifier).toBe(token2.tokenIdentifier);
    await expect(token2a.tokenName).toBe(t2);

    final token1b = await tokenStore.getLocalToken(t1);
    await expect(token1b.tokenIdentifier).toBe(token1.tokenIdentifier);
    await expect(token1b.tokenName).toBe(t1);
    final token2b = await tokenStore.getLocalToken(t2);
    await expect(token2b.tokenIdentifier).toBe(token2.tokenIdentifier);
    await expect(token2b.tokenName).toBe(t2);

    // Requesting with different auth
    await expect(tokenStore.requestAccessToken(t1, await t1Invcred())).toThrow(PowerAuthErrorCode.wrongParameter);
    await expect(tokenStore.requestAccessToken(t2, t2Invcred)).toThrow(PowerAuthErrorCode.wrongParameter);

    // Try calculate tokens
    await expect(tokenStore.generateHeaderForToken(t1)).toSucceed();
    await expect(tokenStore.generateHeaderForToken(t2)).toSucceed();

    // remove locally
    await expect(tokenStore.removeLocalToken(t1)).toSucceed();
    await expect(tokenStore.hasLocalToken(t1)).toBe(false);
    await expect(tokenStore.generateHeaderForToken(t1)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);
    
    // remove on the server
    await expect(tokenStore.removeAccessToken(t2)).toSucceed();
    await expect(tokenStore.hasLocalToken(t2)).toBe(false);
    await expect(tokenStore.generateHeaderForToken(t2)).toThrow(PowerAuthErrorCode.localTokenNotAvailable);
  }

  Future<void> testTokenCalculation() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());
    
    // final activationId = await sdk.getActivationIdentifier();
    
    final t1 = 'possessionToken';
    final t1Cred = credentials.possession();
    final t2 = 'knowledgeToken';
    t2Cred() async { return await credentials.knowledge(); }

    final tokenStore = sdk.tokenStore;

    final token1 = await tokenStore.requestAccessToken(t1, t1Cred);
    await expect(token1.tokenIdentifier).toBeDefined();
    await expect(token1.tokenName).toBe(t1);

    final token2 = await tokenStore.requestAccessToken(t2, await t2Cred());
    await expect(token2.tokenIdentifier).toBeDefined();
    await expect(token2.tokenName).toBe(t2);

    final header1 = await tokenStore.generateHeaderForToken(t1);
    await expect(header1.value).toBeDefined();
    // TODO: not supported in PowerAuth Cloud
    // final result1 = await this.verifyTokenDigest(header1.value); 
    // await expect(result1.tokenValid).toBe(true)
    // await expect(result1.activationId).toBe(activationId)
    // await expect(result1.signatureType).toBe('POSSESSION')

    final header2 = await tokenStore.generateHeaderForToken(t2);
    await expect(header2.value).toBeDefined();
    // TODO: not supported in PowerAuth Cloud
    // final result2 = await this.verifyTokenDigest(header2.value)
    // await expect(result2.tokenValid).toBe(true)
    // await expect(result2.activationId).toBe(activationId)
    // await expect(result2.signatureType).toBe('POSSESSION_KNOWLEDGE')
  }

  // TODO: not support in PowerAuth Cloud 
  //Future<TokenDigestVerifyResult> verifyTokenDigest(TokenDigest digest, { bool timeIsWrong = false}) async {
    // try {
    //   return await helper.tokenHelper.verifyTokenDigest(digest)
    // } catch (error) {
    //   if (error instanceof PowerAuthServerError) {
    //     if (Platform.OS === 'android' && error.httpStatusCode === 400 && error.serverErrorCode === 'ERR0030' && !timeIsWrong) {
    //         this.reportWarning(`It appears that time on Android Device is out of sync`)
    //     }
    //   }
    //   throw error
    // }
  //}
}

// class TokenDigest {
//   final String protocolVersion;
//   final String tokenId;
//   final String tokenDigest;
//   final String nonce;
//   final int timestamp;

//   TokenDigest({
//     required this.protocolVersion,
//     required this.tokenId,
//     required this.tokenDigest,
//     required this.nonce,
//     required this.timestamp,
//   });
// }

// /// Object representing result from token digest validation on the server.
// class TokenDigestVerifyResult {
//   final bool tokenValid;
//   final String activationId;
//   final String userId;
//   final SignatureType signatureType;

//   TokenDigestVerifyResult({
//     required this.tokenValid,
//     required this.activationId,
//     required this.userId,
//     required this.signatureType,
//   });
// }
