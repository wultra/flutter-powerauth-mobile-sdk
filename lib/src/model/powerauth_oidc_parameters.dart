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

/// Parameters for an activation via OpenID connect provider.
class PowerAuthOIDCParameters {
  /// OAuth 2.0 provider identification.
  final String providerId;
  /// OAuth 2.0 authorization code.
  final String code;
  /// Nonce used in the OAuth 2.0 flow.
  final String nonce;
  /// Optional code verifier, in case that PKCE extension is used for an activation.
  final String? codeVerifier;

  PowerAuthOIDCParameters({
    required this.providerId, 
    required this.code, 
    required this.nonce, 
    this.codeVerifier
  });

  /// Converts the parameters to a map representation.
  Map<String, dynamic> toMap() {
    var data = {
      'providerId': providerId,
      'code': code,
      'nonce': nonce,
    };
    if (codeVerifier != null) {
      data['codeVerifier'] = codeVerifier!;
    }
    return data;
  }
}