import 'package:flutter_powerauth_mobile_sdk_plugin/src/powerauth/powerauth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final PowerAuth plugin = PowerAuth();
    final String? version = await plugin.getPlatformVersion();

    expect(version?.isNotEmpty, true);
  });
}
