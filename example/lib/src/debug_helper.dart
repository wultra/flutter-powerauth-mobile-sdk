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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Debug helper class for a direct testing of background isolate functionality.
class DebugHelper {
  static const MethodChannel _channel = MethodChannel('powerauth_plugin');

  static Future<void> startBackgroundIsolate() async {
    if (!kDebugMode) {
      throw Exception(
        'startBackgroundIsolate is only available in DEBUG builds.',
      );
    }

    await _channel.invokeMethod('isolate_startBackgroundIsolate');
  }

  static Future<void> removeBackgroundIsolate() async {
    if (!kDebugMode) {
      throw Exception(
        'removeBackgroundIsolate is only available in DEBUG builds.',
      );
    }

    await _channel.invokeMethod('isolate_removeBackgroundIsolate');
  }
}
