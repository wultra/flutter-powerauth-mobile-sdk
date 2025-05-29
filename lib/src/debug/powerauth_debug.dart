
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth_native_object_register/powerauth_native_object_register.dart';

class PowerAuthDebug {
  /// Indicates whether the debug features are enabled.
  /// Default value is `true` in debug builds and `false` in release builds.
  static var isEnabled = kDebugMode;

  /// Function prints debug information about all native objects registered in native module. Note that the function
  /// is effective ony if native module is compiled in DEBUG mode and if `isEnabled` static property is `true`.
  /// - [instanceId] If provided, then prints only objects that belongs to PowerAuth instance with given identifier.
  static Future<void> dumpNativeObjects({String? instanceId}) async {
      if (!isEnabled) {
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
