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



import 'package:flutter/material.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

import '../config.dart';

class SimpleConfigurationScreen extends StatefulWidget {
  const SimpleConfigurationScreen({super.key});

  @override
  State<SimpleConfigurationScreen> createState() =>
      _SimpleConfigurationScreenState();
}

class _SimpleConfigurationScreenState extends State<SimpleConfigurationScreen> {
  final PowerAuth _powerAuth = PowerAuth("config-instance");

  PowerAuthConfiguration? _configuration;
  String? _status;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    if (await _powerAuth.isConfigured()) {
      await _loadConfiguration();
    } else {
      setState(() {
        _configuration = null;
        _status = "Instance is not configured.";
      });
    }
  }

  Future<void> initPowerauth() async {
    if (await _powerAuth.isConfigured()) {
      print("PowerAuth was already configured.");
    } else {
      try {
        final configuration = PowerAuthConfiguration(
          configuration: AppConfig.sdkConfig,
          baseEndpointUrl: AppConfig.enrollmentUrl,
        );
        final clientConfiguration = PowerAuthClientConfiguration(
          connectionTimeout: 30.0,
        );
        await _powerAuth.configure(configuration: configuration, clientConfiguration: clientConfiguration);

        // powerAuth object configured

      } on PowerAuthException catch (configError) {
        print("PowerAuth configuration failed (Code: ${configError.code}, msg: ${configError.message}). ");
      } catch (configError) {
        print("Failed to auto-configure PowerAuth (Unknown Error): $configError");
      }
    }
  }

  Future<void> _loadConfiguration() async {
    await initPowerauth();
    try {
      final configuration = await _powerAuth.configuration;
      setState(() {
        _configuration = configuration;
        _status = null;
      });
    } on PowerAuthException catch (error) {
      setState(() {
        _configuration = null;
        _status = "Failed to read configuration "
            "(Code: ${error.code}, msg: ${error.message}).";
      });
    } catch (error) {
      setState(() {
        _configuration = null;
        _status = "Failed to read configuration: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Configuration'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_configuration != null) ...[
                Text(
                  'Configuration',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                SelectableText('baseEndpointUrl: ${_configuration!.baseEndpointUrl}'),
                const SizedBox(height: 8),
                SelectableText('configuration: ${_configuration!.configuration.length > 50 ? _configuration!.configuration.substring(0, 50) : _configuration!.configuration}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await _powerAuth.deconfigure();
                    _checkConfiguration();
                  },
                  child: const Text('Deconfigure'),
                ),
              ] else ...[
                Text(
                  _status ?? 'No configuration yet.',
                  textAlign: TextAlign.center,
                ),
                ElevatedButton(
                  onPressed: _loadConfiguration,
                  child: const Text('Initialize Configuration'),
                )],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
