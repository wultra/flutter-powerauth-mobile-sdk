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

import '../model/powerauth_authentication.dart';
import '../model/powerauth_authorization_http_header.dart';
import 'powerauth_platform_interface.dart';

/// The PowerAuthTokenStore provides interface for managing access tokens. The class is using Keychain as 
/// underlying storage for received data. Note that the whole store's interface is thread safe, but it's 
/// not recommended to query for the same token in overlapping asynchronous requests. This usage may lead 
/// to leaking tokens on the PowerAuth server.
class PowerAuthTokenStore {

  static PowerAuthPlatform get _platform => PowerAuthPlatform.instance;

  final String _instanceId;

  /// Creates a new instance of PowerAuthTokenStore.
  PowerAuthTokenStore(this._instanceId);

    /// Quick check whether the token with name is in local database.
    ///
    /// @param tokenName Name of access token to be checked.
    /// @returns true if token exists in local database.
    Future<bool> hasLocalToken(String tokenName) async { 
      return await _platform.hasLocalToken(_instanceId, tokenName);
    }

    /// Returns token if the token is already in local database
    /// 
    /// @param tokenName Name of access token to be returned
    /// @returns token object if in the local database (or throws)
     Future<PowerAuthToken> getLocalToken(String tokenName) async {
      final result = await _platform.getLocalToken(_instanceId, tokenName);
      return PowerAuthToken.fromJson(result);
    }

    /// Remove token from local database. This method doesn't issue a HTTP request to the server.
    ///
    /// @param tokenName token to be removed
    Future<void> removeLocalToken(String tokenName) async {
      await _platform.removeLocalToken(_instanceId, tokenName);
    }

    /// Remove all tokens from local database. This method doesn't issue a HTTP request to the server.
    Future<void> removeAllLocalTokens() async {
      await _platform.removeAllLocalTokens(_instanceId);
    }

    /// Create a new access token with given name for requested signature factors by calling 
    /// a PowerAuth Standard RESTful API endpoint `/pa/token/create`.
    /// 
    /// Note that the method is thread safe, but it's not recommended to request for the same token
    /// name in parallel when the token is not created yet. You can use hasLocalToken() method
    /// to check, whether the token is already in the local database.
    ///
    /// @param tokenName Name of requested token.
    /// @param authentication An authentication instance specifying what factors should be used for token creation.
    /// @returns PowerAuth token with already generated header
    Future<PowerAuthToken> requestAccessToken(String tokenName, PowerAuthAuthentication authentication) async {
      final result = await _platform.requestAccessToken(_instanceId, tokenName, authentication);
      return PowerAuthToken.fromJson(result);
    }

    /// Remove previously created access token from the server and from local database by calling 
    /// a PowerAuth Standard RESTful API endpoint `/pa/token/remove`.
    /// 
    /// Note that if the removal request doesn't succeed, then the local token's data is not removed.
    /// The method is thread safe, but it's not recommended to issue conflicting request for the same
    /// token's name in parallel (e.g. create & remove token at the same time).
    ///
    /// @param tokenName Name of token to be removed
    Future<void> removeAccessToken(String tokenName) async {
      await _platform.removeAccessToken(_instanceId, tokenName);
    }

    /// Generates a http header for the token in local storage.
    /// 
    /// If needed, the method automatically performs time synchronization (via additional HTTP request).
    /// 
    /// @param tokenName Name of token in the local storage that will be used for generating
    /// @returns header or throws
    Future<PowerAuthAuthorizationHttpHeader> generateHeaderForToken(String tokenName) async {
      final result = await _platform.generateHeaderForToken(_instanceId, tokenName);
      return PowerAuthAuthorizationHttpHeader.fromMap(result);
    }
}

class PowerAuthToken {
    /// Symbolic name of token or null if token contains an invalid data.
    String tokenName;
    /// Return token's unique identifier. You normally don't need this value, but it may help
    /// with application's debugging. The value identifies this token on PowerAuth server.
    ///
    /// Null if token contains an invalid data.
    String tokenIdentifier;

    PowerAuthToken(this.tokenName, this.tokenIdentifier);

    /// Creates a PowerAuthToken from JSON data.
    static PowerAuthToken fromJson(Map json) {
      final tokenName = json['tokenName'] as String;
      final tokenIdentifier = json['tokenIdentifier'] as String;
      return PowerAuthToken(tokenName, tokenIdentifier);
    }
}