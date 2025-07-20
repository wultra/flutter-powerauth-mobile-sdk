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

import '../logging/powerauth_logger.dart';

/// Error codes that can be reported by the PowerAuth SDK.
enum PowerAuthErrorCode {

  /// Code returned, or reported, when operation succeeds.
  succeed,

  /// Error code for error with network connectivity or download.
  networkError,

  /// Failed to authenticate on the server. The code is reported when 401 HTTP status code from the server is received.
  authenticationError,

  /// Non 200 HTTP status code received from the server. The [PowerAuthException.errorData] dictionary contains more details.
  responseError,

  /// Error code for error in signature calculation.
  signatureError,

  /// Error code for error that occurs when activation state is invalid.
  invalidActivationState,

  /// Error code for error that occurs when activation data is invalid.
  invalidActivationData,

  /// Error code for error that occurs when activation is required but missing.
  missingActivation,

  /// Error code for error that occurs when pending activation is present and work with completed activation is required.
  pendingActivation,

  /// Error code for canceled operation.
  operationCanceled,

  /// Error code for error that occurs when invalid activation code is provided.
  invalidActivationCode,

  /// Error code for error that occurs when activation object is invalid.
  invalidActivationObject,

  /// Error code for accessing an unknown token.
  invalidToken,

  /// Encryptor is not constructed for encryption or decryption.
  invalidEncryptor,

  /// Error code for errors related to end-to-end encryption.
  encryptionError,

  /// Error code for a general API misuse.
  wrongParameter,

  /// Error code for protocol upgrade failure.
  protocolUpgrade,

  /// The requested function is not available during the protocol upgrade.
  pendingProtocolUpgrade,

  /// Error code for situation when biometric prompt is canceled by the user.
  biometryCancel,

  /// Error code for situation when biometric prompt is canceled by the user with using the fallback button (iOS specific).
  biometryFallback,

  /// The biometric authentication cannot be processed due to lack of required hardware or support.
  biometryNotSupported,

  /// The biometric authentication is temporarily unavailable.
  biometryNotAvailable,

  /// The biometric authentication is not configured in this PowerAuth instance.
  biometryNotConfigured,

  /// The biometric authentication is not enrolled on the device.
  biometryNotEnrolled,

  /// The biometric authentication is locked out due to too many failed attempts.
  biometryLockout,

  /// The biometric authentication did not recognize the biometric image (Android specific).
  biometryNotRecognized,

  /// The keychain protection is not sufficient (Android specific).
  insufficientKeychainProtection,

  /// Error code for a general error related to WatchConnectivity (iOS only).
  watchConnectivity,

  /// Instance of the PowerAuth object is not configured.
  instanceNotConfigured,

  /// Error in `correctTypedCharacter`.
  invalidCharacter,

  /// Error when generating a token.
  cannotGenerateToken,

  /// Error when requesting local token.
  localTokenNotAvailable,

  /// Biometric authentication failed.
  biometryFailed,

  /// The requested function is not available due to an external application is doing the sensitive operation (iOS Specific).
  externalPendingOperation,

  /// Failed with unexpected error.
  unknownError,

  /// Underlying native object is no longer valid.
  invalidNativeObject,

  /// Indicates a problem with the time synchronization.
  timeSynchronization,
}

/// Exception thrown by the PowerAuth SDK.
class PowerAuthException implements Exception {

  /// Code of the error.
  final PowerAuthErrorCode code;

  /// Message describing the error.
  final String? message;

  /// Additional error data (e.g., from server response).
  final Map<String, dynamic>? errorData;

  /// Original exception from the native layer or underlying cause.
  final dynamic cause;

  PowerAuthException({
    required this.code,
    this.message,
    this.errorData,
    this.cause,
  });

  @override
  String toString() {
    return 'PowerAuthException(code: $code, message: $message, errorData: $errorData, cause: $cause)';
  }
}

/// Issues found during the PIN strength test.
enum PinTestIssue {

  /// Not enough unique digits found.
  notUnique,

  /// Too many repeating characters.
  repeatingChars,

  /// There is a pattern in this pin (for example 1357).
  patternFound,

  /// Tested pin could be a date (for example 2512 as birthday - 25th of december).
  possiblyDate,

  /// Tested pin is in TOP used pins (like 1234 as number 1 used pin).
  frequentlyUsed,
}

/// Object representing a PIN strength test result.
class PinTestResult {

  /// If `true` then you should warn the user about a weak PIN.
  final bool shouldWarnUserAboutWeakPin;

  /// List of all issues found during the test.
  final List<PinTestIssue> issues;

  PinTestResult({
    required this.shouldWarnUserAboutWeakPin,
    required this.issues,
  });

  factory PinTestResult.fromMap(Map<dynamic, dynamic> map) {
    List<PinTestIssue> parseIssues(List<dynamic>? issuesList) {
      if (issuesList == null) return [];

      return issuesList
          .map((issueString) {
            try {
              return PinTestIssue.values.firstWhere((e) => e.name == (issueString as String),);
            } catch (e) {
              PowerAuthLogger.warning("Unknown PinTestIssue received: $issueString");
              // TODO: return null or a default?
              return null;
            }
          })
          .whereType<PinTestIssue>()
          .toList();
    }

    return PinTestResult(
      shouldWarnUserAboutWeakPin: map['shouldWarnUserAboutWeakPin'] as bool,
      issues: parseIssues(map['issues'] as List<dynamic>?),
    );
  }
}
