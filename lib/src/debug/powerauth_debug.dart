
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/utils/method_channel_helper.dart';

/// This class provides debug features for the PowerAuth SDK.
/// It allows enabling detailed logging of native code calls and dumping the contents of the native object register.
/// Note that these features are only effective in debug builds of the SDK.
class PowerAuthDebug {

  /// Indicates whether the debug features are enabled.
  /// Value is `true` in debug builds and `false` in release builds (comes from the kDebugMode value).
  static final bool isEnabled = kDebugMode;

  /// Enable or disable detailed log with calls to native code. Be aware that this feature is
  /// effective only if `isEnabled` static property is `true`.
  /// 
  /// - [traceFailure] If set to `true`, then SDK will print a detailed error if native call fails.
  /// - [traceEachCall] If set to `true`, then SDK will print a detailed information about each call to the native code.
  static void traceNativeCodeCalls({ required  traceFailure, bool traceEachCall = false }) {
      if (isEnabled) {
        print("PowerAuthDebug: traceNativeCodeCalls is set to traceFailure=$traceFailure, traceEachCall=$traceEachCall");
        if (traceFailure || traceEachCall) {
          MethodChannelHelper.callTracer = DebugCallTracer(traceEachCall, traceFailure);
        } else {
          MethodChannelHelper.callTracer = NoOpCallTracer();
        }
      } else {
          print("PowerAuthDebug: traceNativeCodeCalls is effective only if isEnabled (debug builds) is true.");
      }
  }

  /// Function prints debug information about all native objects registered in native module. Note that the function
  /// is effective ony if native module is compiled in DEBUG mode and if `isEnabled` static property is `true`.
  /// 
  /// - [instanceId] If provided, then prints only objects that belongs to PowerAuth instance with given identifier.
  static Future<void> dumpNativeObjects({String? instanceId}) async {
      if (!isEnabled) {
        print("PowerAuthDebug: dumpNativeObjects is effective only if isEnabled (debug builds) is true.");
        return;
      }
      if (instanceId != null) {
        print("List of native objects associated with instance '$instanceId' = [");
      } else {
        print('List of all registered native objects = [');
      }
      final printTag = instanceId == null;
      final objectInfo = await NativeObjectRegister.debugDump(instanceId);
      final maxLenId = objectInfo.map((item) => item.id.length).reduce((prev, item) => max(prev,  item));
      final maxLenTag = printTag ? objectInfo.map((item) => item.tag?.length ?? 0).reduce((prev, item) => max(prev, item)) : 0;
      for (final item in objectInfo) {
        final created = DateTime.fromMillisecondsSinceEpoch(item.createDate * 1000);
        final used = item.lastUseDate != null ? ", lastUsed='${DateTime.fromMillisecondsSinceEpoch(item.lastUseDate! * 1000)}" : '';
        final count = item.usageCount != null ? ", used=${item.usageCount}" : "";
        final valid = item.isValid ? '   ' : '!! ';
        final tag = item.tag != null && instanceId == null ? " @ ${item.tag!.padEnd(maxLenTag)}" : '';
        final policies = item.policies.join(', ');
        final objId = item.id.padEnd(maxLenId);
        print("  $valid$objId $tag = { ${item.className}, $policies, created='$created'$used$count }");
      }
      print(']');
  }
}

extension on String {
  /// Pads the string to the right with spaces until it reaches the specified length.
  String padEnd(int targetLength) {
    if (length >= targetLength) return this;
    final padNeeded = targetLength - length;
    final repeatedPad = this * ((padNeeded / length).ceil());
    return this + repeatedPad.substring(0, padNeeded);
  }
}
