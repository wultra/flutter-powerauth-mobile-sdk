
import 'dart:math';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/suites/test_suite.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/utils/integration_helper.dart';

class ActivationTests extends TestSuite {

  // TODO: move to the base "TestSuiteWithActivation" class
  
  late IntegrationHelper _helper;
  late PowerAuth _sdk;
  late ActivationCredentials _credentials;

  @override
  Future<void> beforeEach() async {
    await super.beforeEach();
    _credentials = await generateActivationCredentials();
    _sdk = PowerAuth("test_instance");
    _helper = IntegrationHelper(_sdk);
    await _helper.configure();
  }

  @override
  Future<void> afterEach() async {
    await _sdk.deconfigure();
    await _helper.cleanup();
    await super.afterEach();
  }

  Future<PowerAuthPassword> getPassword() => PowerAuthPassword.fromString("SuperSecurePassword");

  Future<ActivationCredentials> generateActivationCredentials() async {

        final availablePasswords = [ "VerySecure", "1234", "nbusr123", "39h132v,kJdfvAl", "98765", "correct horse battery staple" ];
        final validIndex = Random().nextInt(availablePasswords.length);
        final validPassword = await PowerAuthPassword.fromString(availablePasswords[validIndex], destroyOnUse: false);
        final invalidPassword = await PowerAuthPassword.fromString(availablePasswords[(validIndex + 1) % availablePasswords.length], destroyOnUse: false);
        return ActivationCredentials(
            possession: PowerAuthAuthentication.possession(),
            knowledge: PowerAuthAuthentication.password(validPassword),
            invalidKnowledge: PowerAuthAuthentication.password(invalidPassword),
            biometry: PowerAuthAuthentication.biometry(biometricPrompt: PowerAuthBiometricPrompt(
                promptTitle: 'Authenticate',
                promptMessage: 'Please authenticate with biometry'
            )),
            validPassword: validPassword,
            invalidPassword: invalidPassword
        );
    }

  // END TODO

  @override
  List<Future<void> Function()> getTests() => [createActivationTest];

  Future<void> createActivationTest() async {
        
        await expect(_sdk.canStartActivation()).toBe(true);
        await expect(_sdk.hasPendingActivation()).toBe(false);
        await expect(_sdk.hasValidActivation()).toBe(false);
        await expect(_sdk.getActivationIdentifier()).toBeNull();
        await expect(_sdk.getActivationFingerprint()).toBeNull();
        // await expect(sdk.getExternalPendingOperation()).toBeUndefined()

        await this.runFailingMethodsDuringActivation('BEGIN', PowerAuthErrorCode.missingActivation, PowerAuthErrorCode.missingActivation);
        await expect(_sdk.persistActivation(_credentials.invalidKnowledge)).toThrow(PowerAuthErrorCode.invalidActivationState);

        final activationData = await _helper.createActivation(autoCommit: false);
        final activation = PowerAuthActivation.fromActivationCode(activationCode: activationData.activationCode, name: 'Flutter SDK Test');
        final result = await _sdk.createActivation(activation);
        await expect(result).toBeDefined();
        await expect(result.activationFingerprint).toBeDefined();

        await runFailingMethodsDuringActivation('AFTER_CREATE', PowerAuthErrorCode.pendingActivation, PowerAuthErrorCode.missingActivation);
        await expect(_sdk.createActivation(activation)).toThrow(PowerAuthErrorCode.invalidActivationState);
        
        // Key-exchange should be completed now, so activation Id and fingerprint is now available.
        await expect(await _sdk.canStartActivation()).toBe(false);
        await expect(await _sdk.hasPendingActivation()).toBe(true);
        await expect(await _sdk.hasValidActivation()).toBe(false);

        var activationId = await _sdk.getActivationIdentifier();
        var activationFingerprint = await _sdk.getActivationFingerprint();
        await expect(activationId).toBeDefined();
        await expect(activationFingerprint).toBeDefined();

        var activationDetail = await _helper.getRegistrationDetail();

        await expect(activationDetail.activationFingerprint).toBeDefined(message: "Activation detail should have fingerprint");
        await expect(activationId).toBe(activationDetail.registrationId);
        await expect(result.activationFingerprint).toBe(activationFingerprint);
        await expect(result.activationFingerprint).toBe(activationDetail.activationFingerprint);

        // Now we can persist activation add commit it on the server
        await _helper.commitActivation();
        await _sdk.persistActivation(_credentials.knowledge);

        activationId = await _sdk.getActivationIdentifier();
        activationFingerprint = await _sdk.getActivationFingerprint();
        await expect(activationId).toBeDefined();
        await expect(activationFingerprint).toBeDefined();

        await expect(await _sdk.canStartActivation()).toBe(false);
        await expect(await _sdk.hasPendingActivation()).toBe(false);
        await expect(await _sdk.hasValidActivation()).toBe(true);

        activationDetail = await _helper.getRegistrationDetail();
        await expect(activationDetail.activationFingerprint).toBeNull(); // backend no longer returns fingerprint
        await expect(activationId).toBe(activationDetail.registrationId);
        await expect(result.activationFingerprint).toBe(activationFingerprint);

        // Fetch status now

        final state = (await _sdk.fetchActivationStatus()).state;

        // Validate status

        if (state != PowerAuthActivationState.active) {
          if (state == PowerAuthActivationState.pendingCommit) {
            //this.reportWarning(`State should be ACTIVE but is PENDING_COMMIT`)
          } else {
            // TODO: do better error handling
            throw Exception("State should be ACTIVE but is $state");
          }
        }

        await expect(await _sdk.canStartActivation()).toBe(false);
        await expect(await _sdk.hasPendingActivation()).toBe(false);
        await expect(await _sdk.hasValidActivation()).toBe(true);

        await expect(_sdk.createActivation(activation)).toThrow(PowerAuthErrorCode.invalidActivationState);
        await expect(_sdk.persistActivation(_credentials.invalidKnowledge)).toThrow(PowerAuthErrorCode.invalidActivationState);

        await expect(await _sdk.canStartActivation()).toBe(false);
        await expect(await _sdk.hasPendingActivation()).toBe(false);
        await expect(await _sdk.hasValidActivation()).toBe(true);
    }

  Future<void> runFailingMethodsDuringActivation(String stage, PowerAuthErrorCode expectedFetchError, PowerAuthErrorCode expectedError) async {
    // Fetch has a slighgtly different error handling, so it needs a different error code than other API function.
    // TODO: This should be unified in future versions
    await expect(_sdk.fetchActivationStatus()).toThrow(expectedFetchError);
    await expect(_sdk.removeActivationWithAuthentication(_credentials.invalidKnowledge)).toThrow(expectedError);
    await expect(_sdk.requestGetSignature(_credentials.knowledge, '/some/uriid', null)).toThrow(expectedError);
    await expect(_sdk.requestSignature(_credentials.knowledge, 'POST', '/some/uriid')).toThrow(expectedError);
    await expect(_sdk.changePassword(_credentials.validPassword, _credentials.invalidPassword)).toThrow(expectedError);
    await expect(_sdk.addBiometryFactor(_credentials.validPassword, PowerAuthBiometricPrompt(promptMessage: "desc"))).toThrow(expectedError);
    // TODO: not available in the _sdk yet
    // await expect(_sdk.fetchEncryptionKey(_credentials.knowledge, 99)).toThrow(expectedError);
    // await expect(_sdk.signDataWithDevicePrivateKey(_credentials.knowledge, 'Data')).toThrow(expectedError);
    await expect(_sdk.validatePassword(_credentials.validPassword)).toThrow(expectedError);

    // TODO: following functions should fail and not return false or some different error
    // expect(await _sdk.verifyServerSignedData('c2lnbmF0dXJl', 'c2lnbmF0dXJl', false)).toBe(false);
    // expect(await _sdk.unsafeChangePassword(_credentials.validPassword, _credentials.invalidPassword)).toBe(false);
    await expect(_sdk.removeBiometryFactor()).toThrow(PowerAuthErrorCode.biometryNotConfigured);
    //await expect(async () => await _sdk.offlineSignature(_credentials.knowledge, '/some/uriid', 'MDEyMzQ1Njc=', undefined)).toThrow(PowerAuthErrorCode.MISSING_ACTIVATION})
    //await expect(async () => await _sdk.confirmRecoveryCode('R:ZKMVN-4IMFK-FLSYX-ARRGA', _credentials.knowledge)).toThrow(expectedError);
  }
}

class ActivationCredentials {
    /// Authentication for possession factor only.
    PowerAuthAuthentication possession;
    /// Authentication for possession & knowledge factors.
    PowerAuthAuthentication knowledge;
    /// Authentication for possession & invalid knowledge factors.
    PowerAuthAuthentication invalidKnowledge;
    /// Authenticatio for posession & biometry factors.
    PowerAuthAuthentication biometry;
    /// String with a valid password.
    PowerAuthPassword validPassword;
    /// String with an invalid password.
    PowerAuthPassword invalidPassword;

    ActivationCredentials({
        required this.possession,
        required this.knowledge,
        required this.invalidKnowledge,
        required this.biometry,
        required this.validPassword,
        required this.invalidPassword
    });
}