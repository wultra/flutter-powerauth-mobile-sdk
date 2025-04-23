import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _isConfigured = false;
  final _flutterPowerauthMobileSdkPlugin = PowerAuth("testID");

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    bool isConfigured;
    try {
      platformVersion = await _flutterPowerauthMobileSdkPlugin.getPlatformVersion() ?? 'Unknown platform version';
      isConfigured = await _flutterPowerauthMobileSdkPlugin.isConfigured();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
      isConfigured = false;
    }

    if (isConfigured) {
      print("already configured");
    } else {
     await _flutterPowerauthMobileSdkPlugin.configure(
        configuration: PowerAuthConfiguration(
          configuration: 'ARAVst+fkgOOT/U1gBr1qLMDEOTfEduuLUvbpOmTq7cI+skBAUEEVjKe+8yFg62GvhwU8eE3iEZZCOeNqtEyz2AXXs/yZewnmdETC8J2sNcw5NnIApYDUmBh2n+XRHize4EiVdetjQ==', 
          baseEndpointUrl: 'https://localhost/wrong'
          )
        );
        print("Configured");
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
      _isConfigured = isConfigured;
    });
  }
  
  Future<String> getPlatformVersion() async {
      return await _flutterPowerauthMobileSdkPlugin.getPlatformVersion() ?? 'Unknown platform version';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('PowerAuth testing app: $_isConfigured'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }
}
