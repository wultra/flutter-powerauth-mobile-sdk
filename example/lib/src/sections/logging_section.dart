import 'package:flutter/material.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';

class LoggingSection extends StatelessWidget {
  final List<PowerAuthLog> logs;
  final bool isLoggingEnabled;
  final PowerAuthLogLevel logLevel;
  final Function(bool, PowerAuthLogLevel) onConfigurationChanged;

  const LoggingSection({
    super.key,
    required this.logs,
    required this.isLoggingEnabled,
    required this.logLevel,
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
              value: isLoggingEnabled,
              onChanged: (value) async {
                onConfigurationChanged(value, logLevel);
                await PowerAuthDebug.configureLogging(
                  enabled: value,
                  logLevel: logLevel,
                );
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Log Level:'),
            DropdownButton<PowerAuthLogLevel>(
              value: logLevel,
              onChanged: (PowerAuthLogLevel? newValue) async {
                if (newValue != null) {
                  onConfigurationChanged(isLoggingEnabled, newValue);
                  await PowerAuthDebug.configureLogging(
                    enabled: isLoggingEnabled,
                    logLevel: newValue,
                  );
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
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            PowerAuthLogger.info('This is a test log from the example app.');
          },
          child: const Text('Generate Test Log'),
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
              return ListTile(
                title: Text(log.message),
                subtitle: Text(
                  '${log.level.name.toUpperCase()} - ${log.tag ?? 'No Tag'}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
