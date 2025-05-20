import 'dart:convert';
import 'dart:math';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class IntegrationHelper {
    
  final jsonMediaType = "application/json; charset=UTF-8";
  final PowerAuth sdk;
  CreatedActivation? createdActivation;

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
  Future<void> prepareActiveActivation(PowerAuthPassword password, {String? userId}) async {
        
    final resp = await createActivation(userId: userId);

    // CREATE ACTIVATION LOCALLY

    await sdk.createActivation(PowerAuthActivation.fromActivationCode(activationCode: resp.activationCode, name: "tests"));

    // PERSIST ACTIVATION LOCALLY

    await sdk.persistActivation(PowerAuthAuthentication.persistWithPassword(password));

    // COMMIT ACTIVATION ON THE SERVER

    await _makeCall('{ "externalUserId": "test" }', "${AppConfig.cloudUrl}/v2/registrations/${resp.registrationId}/commit");
  }

  Future<void> configure({
    PowerAuthConfiguration? configuration,
    PowerAuthClientConfiguration? clientConfiguration,
    PowerAuthBiometryConfiguration? biometryConfiguration,
    PowerAuthKeychainConfiguration? keychainConfiguration,
    PowerAuthSharingConfiguration? sharingConfiguration
    }) async {

    // CONFIGURE SDK
    await sdk.configure(
      configuration: configuration ?? PowerAuthConfiguration(configuration: AppConfig.sdkConfig, baseEndpointUrl: AppConfig.enrollmentUrl), 
      clientConfiguration: clientConfiguration, 
      biometryConfiguration: biometryConfiguration, 
      keychainConfiguration: keychainConfiguration, 
      sharingConfiguration: sharingConfiguration
    );

    // REMOVE LOCAL INSTANCE IF PRESENT

    await sdk.removeActivationLocal();
  }

  // --- SERVER CALLS ---

  Future<CreatedActivation> createActivation({String? userId, bool autoCommit = true}) async {

    final activationName = userId ?? _randomString(20);

    final body = """
        {
          "userId": "$activationName",
          "flags": [],
          "appId": "${AppConfig.cloudApplicationId}",
          "commitPhase": "${autoCommit ? "ON_KEY_EXCHANGE" : "ON_COMMIT"}"
        }
        """;
    final resp = await _makeCall(body, "${AppConfig.cloudUrl}/v2/registrations");
    final created = CreatedActivation.fromJson(resp);
    createdActivation = created;
    return created;
  }

  Future<void> commitActivation({String? registrationId}) async {
    await _makeCall("{}", "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}/commit");
  }

  Future<void> removeRegistration({String? registrationId}) async {
    await _makeCall("", "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}", method: HtptMethod.delete);
  }

  Future<RegistrationDetail> getRegistrationDetail({String? registrationId}) async {
    final resp = await _makeCall("", "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}", method: HtptMethod.get);
    return RegistrationDetail.fromJson(resp);
  }

  Future<void> changeActivation(ActivationChange change, {String? registrationId}) async {
    await _makeCall("{\"change\":\"${change.toString()}\"}", "${AppConfig.cloudUrl}/v2/registrations/${registrationId ?? createdActivation?.registrationId}", method: HtptMethod.put);
  }

  Future<SignatureResponse> verifySignature(String method, String uriId, String authHeader, String body) async {
    final payload = """
        {
          "method": "$method",
          "uriId": "$uriId",
          "authHeader": "${authHeader.replaceAll("\"", "\\\"")}",
          "requestBody": "${base64Encode(utf8.encode(body))}"
        }
        """;
    final resp = await _makeCall(payload, "${AppConfig.cloudUrl}/v2/signature/verify", method: HtptMethod.post);
    return SignatureResponse.fromJson(resp);
  }

  // --- HELPER FUNCTIONS ---

  Future<Map<String, dynamic>> _makeCall(String? payload, String stringUrl, { HtptMethod method = HtptMethod.post}) async {

    final url = Uri.parse(stringUrl);
    final creds = "${AppConfig.cloudLogin}:${AppConfig.cloudPassword}";
    Map<String, String>? headers = {
      "authorization": "Basic ${base64Encode(utf8.encode(creds))}",
      'content-type': jsonMediaType
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
        response = await http.patch(url,headers: headers,body: payload);
        break;
      default:
        response = await http.post(url, headers: headers, body: payload);
        break;
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}

enum HtptMethod {
  get,
  post,
  put,
  delete,
  patch,
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
    required this.registrationId
  });

  factory CreatedActivation.fromJson(Map<String, dynamic> json) {
    return CreatedActivation(
      activationCode: json['activationCode'],
      activationCodeSignature: json['activationCodeSignature'],
      activationQrCodeData: json['activationQrCodeData'],
      registrationId: json['registrationId']
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
    this.activationFingerprint
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
      activationFingerprint: json['activationFingerprint']
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
    required this.remainingAttempts
  });

  factory SignatureResponse.fromJson(Map<String, dynamic> json) {
    return SignatureResponse(
      signatureValid: json['signatureValid'],
      userId: json['userId'],
      registrationId: json['registrationId'],
      registrationStatus: json['registrationStatus'],
      signatureType: json['signatureType'],
      remainingAttempts: json['remainingAttempts']
    );
  }
}