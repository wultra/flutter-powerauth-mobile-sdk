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

/// Object representing an authorization HTTP header with the PowerAuth-Authorization or PowerAuth-Token signature.
class PowerAuthAuthorizationHttpHeader {

  /// Property representing the PowerAuth HTTP Authorization Header key.
  /// The value is typically "X-PowerAuth-Authorization" for standard authorization
  /// and "X-PowerAuth-Token" for token-based authorization.
  final String key;

  /// Computed value of the PowerAuth HTTP Authorization Header, to be used in HTTP requests "as is".
  final String value;

  PowerAuthAuthorizationHttpHeader({required this.key, required this.value});

  factory PowerAuthAuthorizationHttpHeader.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthAuthorizationHttpHeader(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }
}
