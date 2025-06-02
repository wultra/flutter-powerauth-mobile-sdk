
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

class PowerAuthActivationTests extends TestSuiteWithActivation {

  @override
  List<Future<void> Function()> getTests() => [
    testCreateActivationWithBareCode, 
    testCreateActivationWithSignedCode,
    testFetchActivationStatus,
    testActivationRemove,
    testVerifyActivationQrCode
  ];

  // --- ACTUAL TESTS STARTS HERE ---

  Future<void> testCreateActivationWithBareCode() async {
    return await createActivationTest(false);
  }
    
  Future<void> testCreateActivationWithSignedCode() async {
    return await createActivationTest(true);
  }

  Future<void> testFetchActivationStatus() async {

    await helper.prepareActiveActivation(await credentials.validPasswordObject());

    await expect(sdk.hasValidActivation()).toBe(true);

    var status = await sdk.fetchActivationStatus();
    await expect(status.state).toBe(PowerAuthActivationState.active);
    await helper.changeActivation(ActivationChange.block);

    status = await sdk.fetchActivationStatus();
    await expect(status.state).toBe(PowerAuthActivationState.blocked);

    await helper.changeActivation(ActivationChange.unblock);
    status = await sdk.fetchActivationStatus();
    await expect(status.state).toBe(PowerAuthActivationState.active);

    await helper.removeRegistration();
    status = await sdk.fetchActivationStatus();
    await expect(status.state).toBe(PowerAuthActivationState.removed);
    await expect(sdk.hasValidActivation()).toBe(true);

    await sdk.removeActivationLocal();
    await expect(await sdk.hasValidActivation()).toBe(false);
  }

  Future<void> testActivationRemove() async {
    await helper.prepareActiveActivation(await credentials.validPasswordObject());
    await sdk.removeActivationWithAuthentication(await credentials.knowledge());
    await expect(sdk.hasValidActivation()).toBe(false);
  }

  Future<void> testVerifyActivationQrCode() async {
    await expect(await sdk.canStartActivation()).toBe(true);

    // Prepare activation on the server
    await helper.createActivation();
    await expect(helper.createdActivation?.activationCode).toBeDefined();
    await expect(helper.createdActivation?.activationCodeSignature).toBeDefined();
  }

  // --- HELPER FUNCTIONS ---

  Future<void> createActivationTest(bool useSignature) async {
      await expect(sdk.canStartActivation()).toBe(true);
      await expect(sdk.hasPendingActivation()).toBe(false);
      await expect(sdk.hasValidActivation()).toBe(false);
      await expect(sdk.getActivationIdentifier()).toBeNull();
      await expect(sdk.getActivationFingerprint()).toBeNull();
      await expect(sdk.getExternalPendingOperation()).toBeNull();

      await runFailingMethodsDuringActivation('BEGIN', PowerAuthErrorCode.missingActivation, PowerAuthErrorCode.missingActivation);
      await expect(sdk.persistActivation(await credentials.invalidKnowledge())).toThrow(PowerAuthErrorCode.invalidActivationState);

      final activationData = await helper.createActivation(autoCommit: false);
      final code = useSignature 
                        ? "${activationData.activationCode}#${activationData.activationCodeSignature}"
                        : activationData.activationCode;
      final activation = PowerAuthActivation.fromActivationCode(activationCode: code, name: 'Flutter SDK Test');
      final result = await sdk.createActivation(activation);
      await expect(result).toBeDefined();
      await expect(result.activationFingerprint).toBeDefined();

      await runFailingMethodsDuringActivation('AFTER_CREATE', PowerAuthErrorCode.pendingActivation, PowerAuthErrorCode.missingActivation);
      await expect(sdk.createActivation(activation)).toThrow(PowerAuthErrorCode.invalidActivationState);
      
      // Key-exchange should be completed now, so activation Id and fingerprint is now available.
      await expect(await sdk.canStartActivation()).toBe(false);
      await expect(await sdk.hasPendingActivation()).toBe(true);
      await expect(await sdk.hasValidActivation()).toBe(false);

      var activationId = await sdk.getActivationIdentifier();
      var activationFingerprint = await sdk.getActivationFingerprint();
      await expect(activationId).toBeDefined();
      await expect(activationFingerprint).toBeDefined();

      var activationDetail = await helper.getRegistrationDetail();

      await expect(activationDetail.activationFingerprint).toBeDefined(message: "Activation detail should have fingerprint");
      await expect(activationId).toBe(activationDetail.registrationId);
      await expect(result.activationFingerprint).toBe(activationFingerprint);
      await expect(result.activationFingerprint).toBe(activationDetail.activationFingerprint);

      // Now we can persist activation add commit it on the server
      await helper.commitActivation();
      await sdk.persistActivation(await credentials.knowledge());

      activationId = await sdk.getActivationIdentifier();
      activationFingerprint = await sdk.getActivationFingerprint();
      await expect(activationId).toBeDefined();
      await expect(activationFingerprint).toBeDefined();

      await expect(await sdk.canStartActivation()).toBe(false);
      await expect(await sdk.hasPendingActivation()).toBe(false);
      await expect(await sdk.hasValidActivation()).toBe(true);

      activationDetail = await helper.getRegistrationDetail();
      await expect(activationDetail.activationFingerprint).toBeNull(); // backend no longer returns fingerprint
      await expect(activationId).toBe(activationDetail.registrationId);
      await expect(result.activationFingerprint).toBe(activationFingerprint);

      // Fetch status now

      final state = (await sdk.fetchActivationStatus()).state;

      // Validate status

      if (state != PowerAuthActivationState.active) {
        reportFailure("State should be ACTIVE but is $state");
      }

      await expect(await sdk.canStartActivation()).toBe(false);
      await expect(await sdk.hasPendingActivation()).toBe(false);
      await expect(await sdk.hasValidActivation()).toBe(true);

      await expect(sdk.createActivation(activation)).toThrow(PowerAuthErrorCode.invalidActivationState);
      await expect(sdk.persistActivation(await credentials.invalidKnowledge())).toThrow(PowerAuthErrorCode.invalidActivationState);

      await expect(await sdk.canStartActivation()).toBe(false);
      await expect(await sdk.hasPendingActivation()).toBe(false);
      await expect(await sdk.hasValidActivation()).toBe(true);
    }

  Future<void> runFailingMethodsDuringActivation(String stage, PowerAuthErrorCode expectedFetchError, PowerAuthErrorCode expectedError) async {
    // Fetch has a slighgtly different error handling, so it needs a different error code than other API function.
    
    await expect(sdk.fetchActivationStatus()).toThrow(expectedFetchError);
    await expect(sdk.removeActivationWithAuthentication(await credentials.invalidKnowledge())).toThrow(expectedError);
    await expect(sdk.requestGetSignature(await credentials.knowledge(), '/some/uriid', null)).toThrow(expectedError);
    await expect(sdk.requestSignature(await credentials.knowledge(), 'POST', '/some/uriid')).toThrow(expectedError);
    await expect(sdk.changePassword(await credentials.validPasswordObject(), await credentials.invalidPasswordObject())).toThrow(expectedError);
    await expect(sdk.addBiometryFactor(await credentials.validPasswordObject(), PowerAuthBiometricPrompt(promptMessage: "desc"))).toThrow(expectedError);
    
    await expect(sdk.fetchEncryptionKey(await credentials.knowledge(), 99)).toThrow(expectedError);
    await expect(sdk.signDataWithDevicePrivateKey(await credentials.knowledge(), 'Data')).toThrow(expectedError);
    await expect(sdk.validatePassword(await credentials.validPasswordObject())).toThrow(expectedError);

    await expect(sdk.verifyServerSignedData('c2lnbmF0dXJl', 'c2lnbmF0dXJl', false)).toBe(false);
    await expect(sdk.removeBiometryFactor()).toThrow(PowerAuthErrorCode.biometryNotConfigured);
    await expect(sdk.offlineSignature(await credentials.knowledge(), '/some/uriid', 'MDEyMzQ1Njc=', null)).toThrow(PowerAuthErrorCode.missingActivation);
  }
}