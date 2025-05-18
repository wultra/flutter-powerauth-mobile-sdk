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

import 'powerauth_basic_http_authentication.dart';
import 'powerauth_http_header.dart';

/// Class that contains configuration for RESTful API client used internally by SDK.
class PowerAuthClientConfiguration {

  /// Defines whether unsecured connection is allowed. Defaults to `false`.
  final bool enableUnsecureTraffic;

  /// Connection timeout in seconds. Defaults to 20 seconds.
  final double connectionTimeout;

  /// Read timeout in seconds. Be aware that this parameter is ignored on Apple platforms.
  /// Defaults to 20 seconds.
  final double readTimeout;

  /// Custom HTTP headers that will be added to each HTTP request produced by this library.
  final List<PowerAuthHttpHeader>? customHttpHeaders;

  /// Basic HTTP Authentication that will be added to each HTTP request produced by this library.
  final PowerAuthBasicHttpAuthentication? basicHttpAuthentication;

  PowerAuthClientConfiguration({
    this.enableUnsecureTraffic = false,
    this.connectionTimeout = 20.0,
    this.readTimeout = 20.0,
    this.customHttpHeaders,
    this.basicHttpAuthentication,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableUnsecureTraffic': enableUnsecureTraffic,
      'connectionTimeout': connectionTimeout,
      'readTimeout': readTimeout,
      'customHttpHeaders': customHttpHeaders?.map((h) => h.toMap()).toList(),
      'basicHttpAuthentication': basicHttpAuthentication?.toMap(),
    };
  }
}
