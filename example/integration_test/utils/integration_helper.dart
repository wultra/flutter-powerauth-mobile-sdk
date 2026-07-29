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
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_powerauth_mobile_sdk_plugin_example/config.dart';

class IntegrationHelper {
  final jsonMediaType = "application/json; charset=UTF-8";
  final PowerAuth sdk;
  CreatedActivation? createdActivation;
  String? userId;

  IntegrationHelper(this.sdk);

  Future<void> cleanup() async {
    if (await sdk.isConfigured() == false) {
      return;
    }

    final activationId = await sdk.getActivationIdentifier();

    // REMOVE ACTIVATION LOCALLY
    await sdk.removeActivationLocal();

    // REMOVE ACTIVATION ON THE SERVER
    if (activationId != null) {
      await removeRegistration(registrationId: activationId);
    }

    await sdk.deconfigure();
  }

  // --- COMPLEX TASKS ---

  /// Creates a new activation on the server and locally.
  Future<void> prepareActiveActivation(
    PowerAuthPassword password, {
    String? userId,
    bool setupBiometry = false,
    String biometryPrompt = "Create activation with biometrics",
  }) async {
    final resp = await createActivation(userId: userId);

    // CREATE ACTIVATION LOCALLY

    await sdk.createActivation(
      PowerAuthActivation.fromActivationCode(
        activationCode: resp.activationCode,
        name: "tests",
      ),
    );

    // PERSIST ACTIVATION LOCALLY

    await sdk.persistActivation(
      setupBiometry
          ? PowerAuthAuthentication.persistWithPasswordAndBiometry(
            password: password,
            biometricPrompt: PowerAuthBiometricPrompt(
              promptMessage: biometryPrompt,
            ),
          )
          : PowerAuthAuthentication.persistWithPassword(password),
    );

    // COMMIT ACTIVATION ON THE SERVER

    await _makeCall(
      '{ "externalUserId": "test" }',
      "${AppConfig.cloudUrl}/v2/registrations/${resp.registrationId}/commit",
      backend: _IntegrationBackend.cloud,
    );
  }

  Future<void> configure({
    PowerAuthConfiguration? configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration,
    bool automatedTesting = false,
  }) async {
    await AppConfig.ensureLoaded();

    // CONFIGURE SDK
    await sdk.configure(
      configuration:
          configuration ??
          PowerAuthConfiguration(
            configuration: AppConfig.sdkConfig,
            baseEndpointUrl: AppConfig.enrollmentUrl,
          ),
      clientConfiguration: clientConfiguration,
      biometryConfiguration:
          biometryConfiguration ??
          (automatedTesting
              ? PowerAuthBiometryConfiguration(
                authenticateOnBiometricKeySetup: false,
                confirmBiometricAuthentication: false,
                fallbackToDevicePasscode: false,
                invalidateBiometricFactorAfterChange: true,
              )
              : null),
      keychainConfiguration: keychainConfiguration,
      sharingConfiguration: sharingConfiguration,
    );

    // REMOVE LOCAL INSTANCE IF PRESENT

    await sdk.removeActivationLocal();
  }

  // --- SERVER CALLS ---

  Future<CreatedActivation> createActivation({
    String? userId,
    bool autoCommit = true,
  }) async {
    final activationName = userId ?? randomString(20);
    this.userId = activationName;

    final body = """
        {
          "userId": "$activationName",
          "flags": [],
          "appId": "${AppConfig.cloudApplicationId}",
          "commitPhase": "${autoCommit ? "ON_KEY_EXCHANGE" : "ON_COMMIT"}"
        }
        """;
    final resp = await _makeCall(
      body,
      "${AppConfig.cloudUrl}/v2/registrations",
      backend: _IntegrationBackend.cloud,
    );
    final created = CreatedActivation.fromJson(resp);
    createdActivation = created;
    return created;
  }

  Future<void> commitActivation({String? registrationId}) async {
    await _makeCall(
      "{}",
      "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}/commit",
      backend: _IntegrationBackend.cloud,
    );
  }

  Future<void> removeRegistration({String? registrationId}) async {
    await _makeCall(
      "",
      "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}",
      backend: _IntegrationBackend.cloud,
      method: HtptMethod.delete,
    );
  }

  Future<RegistrationDetail> getRegistrationDetail({
    String? registrationId,
  }) async {
    final resp = await _makeCall(
      "",
      "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}",
      backend: _IntegrationBackend.cloud,
      method: HtptMethod.get,
    );
    return RegistrationDetail.fromJson(resp);
  }

  Future<void> changeActivation(
    ActivationChange change, {
    String? registrationId,
  }) async {
    await _makeCall(
      "{\"change\":\"${change.toString()}\"}",
      "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}",
      backend: _IntegrationBackend.cloud,
      method: HtptMethod.put,
    );
  }

  Future<SignatureResponse> verifySignature(
    String method,
    String uriId,
    String authHeader,
    String body, {
    Map<String, String>? queryParams,
  }) async {
    final isGet = method.toUpperCase() == 'GET';
    final payload = jsonEncode({
      'method': method,
      'uriId': uriId,
      'authHeader': authHeader,
      'requestBody': isGet ? null : base64Encode(utf8.encode(body)),
      'queryParams': isGet ? queryParams : null,
    });
    final resp = await _makeCall(
      payload,
      "${AppConfig.cloudUrl}/v2/signature/verify",
      backend: _IntegrationBackend.cloud,
      method: HtptMethod.post,
    );
    return SignatureResponse.fromJson(resp);
  }

  Future<TokenResponse> verifyToken(String authHeader) async {
    final payload = """
        {
          "authHeader": "${authHeader.replaceAll("\"", "\\\"")}"
        }
        """;
    final resp = await _makeCall(
      payload,
      "${AppConfig.cloudUrl}/v2/token/verify",
      backend: _IntegrationBackend.cloud,
      method: HtptMethod.post,
    );
    return TokenResponse.fromJson(resp);
  }

  /// Creates deterministic user claims for user-info integration tests.
  PowerAuthUserInfo userInfo(String userId) {
    return PowerAuthUserInfo({
      'sub': userId,
      'name': 'Name $userId',
      'given_name': 'given',
      'family_name': 'family',
      'middle_name': 'middle',
      'nickname': 'nickname',
      'preferred_username': 'preferred$userId',
      'profile': 'https://wultra.com/profile',
      'picture': 'https://wultra.com/icon.png',
      'website': 'https://wultra.com',
      'email': '$userId@wultra.com',
      'email_verified': true,
      'phone_number': '+56 (2) 687 2400',
      'phone_number_verified': true,
      'gender': 'female',
      'birthdate': '2000-04-01',
      'zoneinfo': 'Europe/Prague',
      'locale': 'cs-CZ',
      'updated_at': 1746120021,
      'address': {
        'formatted': 'Street 1, Prague, Czech Republic',
        'street_address': 'Street 1',
        'locality': 'Prague',
        'region': 'Prague',
        'postal_code': '10000',
        'country': 'Czech Republic',
      },
    });
  }

  /// Stores user claims in User Data Store.
  Future<Map<String, dynamic>> fillUserInfo(PowerAuthUserInfo userInfo) async {
    await AppConfig.ensureLoaded();
    if (AppConfig.isUdsConfigMissing()) {
      throw StateError(
        'User Data Store configuration is missing. Set UDS_SERVER_URL, '
        'UDS_SERVER_USERNAME, and UDS_SERVER_PASSWORD in example/.env.',
      );
    }

    final subject = userInfo.subject;
    if (subject == null) {
      throw ArgumentError.value(userInfo, 'userInfo', 'Subject is required');
    }
    final userId = Uri.encodeQueryComponent(subject);
    return _makeCall(
      jsonEncode(userInfo.allClaims),
      "${AppConfig.udsServerUrl}/public/user-claims?userId=$userId",
      backend: _IntegrationBackend.userDataStore,
    );
  }

  // --- HELPER FUNCTIONS ---

  Future<RawHttpResponse> callRawSDKEndpoint(
    String endpoint, {
    Uint8List? body,
    Iterable<PowerAuthHttpHeader> headers = const [],
  }) async {
    final configuration = await sdk.configuration;
    final algorithm = await sdk.currentAlgorithm;
    final apiVersion =
        algorithm == PowerAuthAlgorithm.legacy ? 'pa/v3' : 'pa/v4';
    final base = configuration.baseEndpointUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = endpoint.replaceFirst(RegExp(r'^/+'), '');
    final url = Uri.parse('$base/$apiVersion/$path');
    final response = await http.post(
      url,
      headers: {for (final header in headers) header.name: header.value},
      body: body,
    );
    final result = RawHttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      bodyBytes: response.bodyBytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'SDK endpoint $url failed with HTTP ${response.statusCode}; '
        'headers=${response.headers}; bodyBytes=${response.bodyBytes}',
      );
    }
    return result;
  }

  Future<Map<String, dynamic>> _makeCall(
    String? payload,
    String stringUrl, {
    required _IntegrationBackend backend,
    HtptMethod method = HtptMethod.post,
  }) async {
    final url = Uri.parse(stringUrl);
    final creds = switch (backend) {
      _IntegrationBackend.cloud =>
        "${AppConfig.cloudLogin}:${AppConfig.cloudPassword}",
      _IntegrationBackend.userDataStore =>
        "${AppConfig.udsServerUsername}:${AppConfig.udsServerPassword}",
    };
    Map<String, String>? headers = {
      "authorization": "Basic ${base64Encode(utf8.encode(creds))}",
      'content-type': jsonMediaType,
    };

    http.Response response;

    switch (method) {
      case HtptMethod.get:
        response = await http.get(url, headers: headers);
        break;
      case HtptMethod.put:
        response = await http.put(url, headers: headers, body: payload);
        break;
      case HtptMethod.delete:
        response = await http.delete(url, headers: headers);
        break;
      case HtptMethod.patch:
        response = await http.patch(url, headers: headers, body: payload);
        break;
      default:
        response = await http.post(url, headers: headers, body: payload);
        break;
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String randomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }
}

enum HtptMethod { get, post, put, delete, patch }

enum _IntegrationBackend { cloud, userDataStore }

class RawHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  RawHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });
}

class CreatedActivation {
  final String activationCode;
  final String activationCodeSignature;
  final String activationQrCodeData;
  final String registrationId;

  CreatedActivation({
    required this.activationCode,
    required this.activationCodeSignature,
    required this.activationQrCodeData,
    required this.registrationId,
  });

  factory CreatedActivation.fromJson(Map<String, dynamic> json) {
    return CreatedActivation(
      activationCode: json['activationCode'],
      activationCodeSignature: json['activationCodeSignature'],
      activationQrCodeData: json['activationQrCodeData'],
      registrationId: json['registrationId'],
    );
  }
}

class RegistrationDetail {
  String? registrationId;
  String? registrationStatus;
  String? blockedReason;
  String? applicationId;
  String? name;
  String? platform;
  String? deviceInfo;
  List<String>? flags;
  int? timestampCreated;
  int? timestampLastUsed;
  String? userId;
  String? activationQrCodeData;
  String? activationCode;
  String? activationCodeSignature;
  String? activationFingerprint;

  RegistrationDetail({
    this.registrationId,
    this.registrationStatus,
    this.blockedReason,
    this.applicationId,
    this.name,
    this.platform,
    this.deviceInfo,
    this.flags,
    this.timestampCreated,
    this.timestampLastUsed,
    this.userId,
    this.activationQrCodeData,
    this.activationCode,
    this.activationCodeSignature,
    this.activationFingerprint,
  });

  factory RegistrationDetail.fromJson(Map<String, dynamic> json) {
    List<String>? flags;
    if (json['flags'] != null) {
      flags = List<String>.from(json['flags']);
    }
    return RegistrationDetail(
      registrationId: json['registrationId'],
      registrationStatus: json['registrationStatus'],
      blockedReason: json['blockedReason'],
      applicationId: json['applicationId'],
      name: json['name'],
      platform: json['platform'],
      deviceInfo: json['deviceInfo'],
      flags: flags,
      timestampCreated: json['timestampCreated'],
      timestampLastUsed: json['timestampLastUsed'],
      userId: json['userId'],
      activationQrCodeData: json['activationQrCodeData'],
      activationCode: json['activationCode'],
      activationCodeSignature: json['activationCodeSignature'],
      activationFingerprint: json['activationFingerprint'],
    );
  }
}

enum ActivationChange {
  block,
  unblock;

  @override
  String toString() {
    switch (this) {
      case ActivationChange.block:
        return "BLOCK";
      case ActivationChange.unblock:
        return "UNBLOCK";
    }
  }
}

class SignatureResponse {
  final bool signatureValid;
  final String userId;
  final String registrationId;
  final String registrationStatus;
  final String signatureType;
  final int remainingAttempts;

  SignatureResponse({
    required this.signatureValid,
    required this.userId,
    required this.registrationId,
    required this.registrationStatus,
    required this.signatureType,
    required this.remainingAttempts,
  });

  factory SignatureResponse.fromJson(Map<String, dynamic> json) {
    return SignatureResponse(
      signatureValid: json['signatureValid'],
      userId: json['userId'],
      registrationId: json['registrationId'],
      registrationStatus: json['registrationStatus'],
      signatureType: json['signatureType'],
      remainingAttempts: json['remainingAttempts'],
    );
  }
}

class TokenResponse {
  final bool tokenValid;
  final String? userId;
  final String? registrationId;
  final String? registrationStatus;
  final String? signatureType;

  TokenResponse({
    required this.tokenValid,
    required this.userId,
    required this.registrationId,
    required this.registrationStatus,
    required this.signatureType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      tokenValid: json['tokenValid'],
      userId: json['userId'],
      registrationId: json['registrationId'],
      registrationStatus: json['registrationStatus'],
      signatureType: json['signatureType'],
    );
  }
}
