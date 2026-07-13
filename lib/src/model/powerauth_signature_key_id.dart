/*
 * Copyright 2026 Wultra s.r.o.
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

/// Identifies a key used for digital signature calculation or verification.
enum PowerAuthSignatureKeyId {
  /// All available master server keys.
  master,

  /// The EC-based master server key.
  masterEc,

  /// The ML-DSA-based master server key.
  masterMlDsa,

  /// All available personalized server keys.
  server,

  /// The EC-based personalized server key.
  serverEc,

  /// The ML-DSA-based personalized server key.
  serverMlDsa,

  /// All available device keys.
  device,

  /// The EC-based device key.
  deviceEc,

  /// The ML-DSA-based device key.
  deviceMlDsa,

  /// The personalized KMAC-based symmetric key.
  macPersonalized,
}