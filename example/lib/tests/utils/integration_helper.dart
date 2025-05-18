import 'dart:convert';
import 'dart:math';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';

class IntegrationHelper {
    
  final jsonMediaType = "application/json; charset=UTF-8";
  final PowerAuth sdk;

  IntegrationHelper(this.sdk);

  Future<void> prepareActivation({
    required PowerAuthPassword password,
    String? userId
  }) async {

    // Be sure that each activation has its own user
    final activationName = userId ?? _randomString(20);

    // CREATE ACTIVATION ON THE SERVER

    final body = """
        {
          "userId": "$activationName",
          "flags": [],
          "appId": "${AppConfig.cloudApplicationId}"
        }
        """;
        
    final resp = await _makeCall(body,"${AppConfig.cloudUrl}/v2/registrations");

    // CREATE ACTIVATION LOCALLY

    await sdk.createActivation(PowerAuthActivation.fromActivationCode(activationCode: resp["activationCode"], name: "tests"));

    // PERSIST ACTIVATION LOCALLY

    await sdk.persistActivation(PowerAuthAuthentication.persistWithPassword(password));

    // COMMIT ACTIVATION ON THE SERVER

    await _makeCall('{ "externalUserId": "test" }', "${AppConfig.cloudUrl}/v2/registrations/${resp["registrationId"]}/commit");
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

  Future<void> removeRegistration(String activationId) async {
    await _makeCall("", "${AppConfig.cloudUrl}/v2/registrations/$activationId", method: HtptMethod.delete);
  }

    // async createOperation(): Promise<OperationObject> {
    //     const opBody = `
    //         {
    //           "userId": "${this.activationName}",
    //           "template": "login",
    //            "parameters": {
    //              "party.id": "666",
    //              "party.name": "Datová schránka",
    //                  "session.id": "123",
    //                  "session.ip-address": "192.168.0.1"
    //            }
    //         }
    //         `

    //     // create an operation on the nextstep server
    //     return await this.makeCall(opBody, `${this.cloudServerUrl}/v2/operations`)
    // }

    // async cancelOperation(operationId: string, reason: string): Promise<any> {
    //     return await this.makeCall("", `${this.cloudServerUrl}/v2/operations/${operationId}?statusReason=${reason}`, "DELETE")
    // }

    // async createNonPersonalizedPACOperation(): Promise<OperationObject> {
    //     const opBody = `
    //         {
    //           "template": "login_preApproval",
    //           "proximityCheckEnabled": true,
    //            "parameters": {
    //              "party.id": "666",
    //              "party.name": "Datová schránka",
    //                  "session.id": "123",
    //                  "session.ip-address": "192.168.0.1"
    //            }
    //         }
    //         `
    //     // create an operation on the nextstep server
    //     return await this.makeCall(opBody, `${this.cloudServerUrl}/v2/operations`)
    // }

    // async getOperation(operationId: string): Promise<OperationObject> {
    //     return await this.makeCall(undefined, `${this.cloudServerUrl}/v2/operations/${operationId}`, "GET")
    // }

    // async getQROperation(operationId: string): Promise<QRData> {
    //     return await this.makeCall(undefined, `${this.cloudServerUrl}/v2/operations/${operationId}/offline/qr?registrationId=${this.registrationId}`, "GET")
    // }

    // async verifyQROperation(operation: OperationObject, qrData: QRData, otp: string): Promise<QROperationVerify> {
    //     const body = `
    //         {
    //           "otp": "${otp}",
    //           "nonce": "${qrData.nonce}",
    //           "registrationId": "${this.registrationId}"
    //         }
    //     `
    //     return this.makeCall(body, `${this.cloudServerUrl}/v2/operations/${operation.operationId}/offline/otp`)
    // }

    // async createInboxMessages(count: number, type: string = "text"): Promise<NewInboxMessage[]> {
    //     const result: NewInboxMessage[] = []
    //     for (let i = 0; i < count; i++) {
    //         const body = `
    //             {
    //                 "userId":"${this.activationName}",
    //                 "subject":"Message #${i}",
    //                 "summary":"This is body for message ${i}",
    //                 "body":"This is body for message ${i}",
    //                 "type":"${type}",
    //                 "silent":true
    //             }
    //         `
    //         const newMessage = await this.makeCall(body, `${this.cloudServerUrl}/v2/inbox/messages`)
    //         result.push(newMessage)
    //     }
    //     return result
    // }

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

// interface RegistrationObject {
//     activationCode: string
//     activationCodeSignature: string
//     activationQrCodeData: string
//     registrationId: string
// }

// interface OperationObject {
//     operationId: string
//     userId: string
//     status: string
//     operationType: string
//     // val parameters: [] // not needed for test right now
//     failureCount: number
//     maxFailureCount: number
//     timestampCreated: number
//     timestampExpires: number
//     proximityOtp: string | undefined
// }

// interface QRData {
//     operationQrCodeData: string,
//     nonce: string
// }

// interface QROperationVerify {
//     otpValid: boolean
//     userId: string
//     registrationId: string
//     registrationStatus: string
//     signatureType: string
//     remainingAttempts: number
//     // flags: []
//     // application
// }

// import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

// export interface NewInboxMessage {
//     id: string
//     subject: string
//     summary: string
//     body: string
//     read: boolean
//     type: string
//     timestamp: number
// }

enum HtptMethod {
  get,
  post,
  put,
  delete,
  patch,
}