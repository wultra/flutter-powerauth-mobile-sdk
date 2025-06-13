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