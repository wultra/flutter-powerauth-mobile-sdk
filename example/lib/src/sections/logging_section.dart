import 'package:flutter/material.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

class LoggingSection extends StatelessWidget {
  final List<PowerAuthLog> logs;
  final PowerAuthLoggingConfig loggingConfig;
  final Function(PowerAuthLoggingConfig) onConfigurationChanged;

  const LoggingSection({
    super.key,
    required this.logs,
    required this.loggingConfig,
    required this.onConfigurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Enable Logging:'),
            Switch(
              value: loggingConfig.enabled,
              onChanged: (value) async {
                final newConfig = loggingConfig.copyWith(enabled: value);
                onConfigurationChanged(newConfig);
                await PowerAuthDebug.configureLogging(newConfig);
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Log Level:'),
            DropdownButton<PowerAuthLogLevel>(
              value: loggingConfig.level,
              onChanged: (PowerAuthLogLevel? newValue) async {
                if (newValue != null) {
                  final newConfig = loggingConfig.copyWith(level: newValue);
                  onConfigurationChanged(newConfig);
                  await PowerAuthDebug.configureLogging(newConfig);
                }
              },
              items:
                  PowerAuthLogLevel.values
                      .map<DropdownMenuItem<PowerAuthLogLevel>>(
                        (level) => DropdownMenuItem<PowerAuthLogLevel>(
                          value: level,
                          child: Text(level.name.toUpperCase()),
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Log to Console:'),
            Switch(
              value: loggingConfig.logToConsole,
              onChanged: (value) async {
                final newConfig = loggingConfig.copyWith(logToConsole: value);
                onConfigurationChanged(newConfig);
                await PowerAuthDebug.configureLogging(newConfig);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final timestamp = log.timestamp;
              final formattedTime =
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
              return ListTile(
                title: Text(log.message),
                subtitle: Text(
                  '$formattedTime - ${log.level.name.toUpperCase()} - ${log.tag ?? 'No Tag'}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
