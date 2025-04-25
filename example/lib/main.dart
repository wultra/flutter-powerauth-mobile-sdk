import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

void main() {
  runApp(MaterialApp(home: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _isConfigured = 'Unknown';
  String _hasValidActivation = 'Unknown';
  String _canStartActivation = 'Unknown';
  String _hasPendingActivation = 'Unknown';
  String _activationIdentifier = 'Unknown';
  String _activationFingerprint = 'Unknown';
  String _activationStatus = 'Unknown';

  final _sdk = PowerAuth("testID");

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _sdk.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    await _sdk.configure(
      configuration: PowerAuthConfiguration(
        configuration:'FILL_IN_YOUR_CONFIGURATION',
        baseEndpointUrl: 'FILL_IN_YOUR_BASE_URL',
      ),
    );

    updatePowerAuthState();

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<String> getPlatformVersion() async {
    return await _sdk.getPlatformVersion() ?? 'Unknown platform version';
  }

  void updatePowerAuthState() async {
    var statusString = "N/A";
    try {
      statusString = JsonEncoder().convert(await _sdk.fetchActivationStatus());
    } catch (e) {
      print(e);
    }

    var isConfigured = await _sdk.isConfigured() ? 'true' : 'false';
    var hasValidActivation = await _sdk.hasValidActivation() ? 'true' : 'false';
    var canStartActivation = await _sdk.canStartActivation() ? 'true' : 'false';
    var hasPendingActivation = await _sdk.hasPendingActivation() ? 'true' : 'false';
    var activationIdentifier = await _sdk.getActivationIdentifier() ?? 'N/A';
    var activationFingerprint = await _sdk.getActivationFingerprint() ?? 'N/A';
    var activationStatus = statusString;

    setState(() {
      _isConfigured = isConfigured;
      _hasValidActivation = hasValidActivation;
      _canStartActivation = canStartActivation;
      _hasPendingActivation = hasPendingActivation;
      _activationIdentifier = activationIdentifier;
      _activationFingerprint = activationFingerprint;
      _activationStatus = activationStatus;
    });
  }

  void createActivation(String code) async {
    try {
      await _sdk.createActivation(
        PowerAuthActivation.fromActivationCode(
          activationCode: code,
          name: "flutter-test",
        )
      );
      updatePowerAuthState();
    } catch (e) {
      print(e);
    }
  }

  void persistActivation(String password) async {
    try {
      var paPassword = PowerAuthPassword();
      for (var i = 0; i < password.length; i++) {
        paPassword.addCharacter(password[i]);
      }
      await _sdk.persistActivation(
        PowerAuthAuthentication.persistWithPassword(paPassword),
      );
      updatePowerAuthState();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('PowerAuth testing app')),
        body: Center(
          child: Column(
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('PA STATE:'),
              Text('isConfigured: $_isConfigured'),
              Text('hasValidActivation: $_hasValidActivation'),
              Text('canStartActivation: $_canStartActivation'),
              Text('hasPendingActivation: $_hasPendingActivation'),
              Text('activationIdentifier:\n$_activationIdentifier', textAlign: TextAlign.center),
              Text('activationFingerprint: $_activationFingerprint'),
              Text('activationStatus: $_activationStatus'),
              ElevatedButton(
                onPressed: () {
                  updatePowerAuthState();
                },
                child: const Text('Update PowerAuth state'),
              ),
              ElevatedButton(
                onPressed: () async {
                  var activationCode = await _showTextInputDialog(context, "Enter activation code");
                  if (activationCode != null && activationCode.isNotEmpty) {
                    createActivation(activationCode);
                  }
                },
                child: const Text('Create Registration'),
              ),
              ElevatedButton(
                onPressed: () async {
                  var password = await _showTextInputDialog(context, "Enter password");
                  if (password != null && password.isNotEmpty) {
                    persistActivation(password);
                  }
                },
                child: const Text('Persist Registration'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showTextInputDialog(
    BuildContext context,
    String title,
  ) async {
    final controller = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller),
          actions: <Widget>[
            ElevatedButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
    );
  }
}
