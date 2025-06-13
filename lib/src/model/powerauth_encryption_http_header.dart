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

/// HTTP header used for end-to-end encryption.
class PowerAuthEncryptionHttpHeader {

  /// Name of the HTTP header
  final String name;

  /// Value of the HTTP header
  final String value;

  PowerAuthEncryptionHttpHeader({required this.name, required this.value});

  /// Creates a [PowerAuthEncryptionHttpHeader] from a map.
  factory PowerAuthEncryptionHttpHeader.fromMap(Map<dynamic, dynamic> map) {
    return PowerAuthEncryptionHttpHeader(
      name: map['name'] as String,
      value: map['value'] as String,
    );
  }

  /// Converts this [PowerAuthEncryptionHttpHeader] to a map.
  Map<String, dynamic> toMap() {
    return {'name': name, 'value': value};
  }
}
