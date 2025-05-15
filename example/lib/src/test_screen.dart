import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin/flutter_powerauth_mobile_sdk_plugin.dart';
import 'package:flutter_powerauth_mobile_sdk_plugin_example/tests/tests.dart';

import '../config.dart';

// Helper to generate a fixed-size random nonce
String _generateRandomNonce() {
  final random = Random.secure();
  final nonceBytes = Uint8List(16);

  for (int i = 0; i < nonceBytes.length; i++) {
    nonceBytes[i] = random.nextInt(256);
  }

  return base64Encode(nonceBytes);
}

class PowerAuthTestingScreen extends StatefulWidget {
  const PowerAuthTestingScreen({super.key});

  @override
  State<PowerAuthTestingScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<PowerAuthTestingScreen> {
  late PowerAuth _powerAuth;
  String _instanceId = "dev";

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isConfigured = false;
  bool? _hasValidActivation;
  bool? _canStartActivation;
  bool? _hasPendingActivation;
  String? _activationId;
  String? _activationFingerprint;
  PowerAuthActivationStatus? _activationStatus;
  bool? _hasBiometryFactor;
  PowerAuthBiometryInfo? _biometryInfo;

  @override
  void initState() {
    super.initState();
    _powerAuth = PowerAuth(_instanceId);
  }

  Future<void> _initializeAndRefresh() async {
    _isInitialized = true;
    _setLoading(true);

    _isConfigured = await _powerAuth.isConfigured();
    if (_isConfigured) {
      await _refreshState();
    } else {
      if (AppConfig.isConfigMissing()) {
        _setError("PowerAuth configuration is missing or invalid. ");
        _setLoading(false);

        return;
      }

      try {
        final powerAuthConfig = PowerAuthConfiguration(
          configuration: AppConfig.powerAuthConfigString,
          baseEndpointUrl: AppConfig.baseUrl,
        );

        final biometryConfig = PowerAuthBiometryConfiguration();
        final keychainConfig = PowerAuthKeychainConfiguration(minimalRequiredKeychainProtection: PowerAuthKeychainProtection.software);
        final clientConfig = PowerAuthClientConfiguration(enableUnsecureTraffic: false);
        final sharingConfig = PowerAuthSharingConfiguration(appGroup: "group.com.wultra.testGroup", appIdentifier: "SharedInstanceTests", keychainAccessGroup: "fake.accessGroup", sharedMemoryIdentifier: "tst1");

        await _powerAuth.configure(
          configuration: powerAuthConfig,
          biometryConfiguration: biometryConfig,
          clientConfiguration: clientConfig,
          keychainConfiguration: keychainConfig,
          sharingConfiguration: sharingConfig
        );
        print('PowerAuth configured successfully for instance: $_instanceId');

        _isConfigured = true;
        await _refreshState();
      } on PowerAuthException catch (configError) {
        _setError(
          "PowerAuth configuration failed (Code: ${configError.code}, msg: ${configError.message}). ",
        );
        _isConfigured = false;
        _setLoading(false);
      } catch (configError) {
        _setError(
          'Failed to auto-configure PowerAuth (Unknown Error): $configError',
        );
        _isConfigured = false;
        _setLoading(false);
      }
    }
  }

  Future<void> _refreshState() async {
    if (!_isConfigured) {
      print('Cannot refresh state: PowerAuth instance not configured.');
      if (_isLoading) _setLoading(false);

      return;
    }

    if (!_isLoading) _setLoading(true);
    _clearError();

    PowerAuthActivationStatus? activationStatus;
    try {
      activationStatus = await _powerAuth.fetchActivationStatus();
    } catch (e) {
      print("Failed to fetch activation status: $e");
    }

    try {
      // TODO: it will perhaps be better so separate this later. Future failing on first error is too flaky.
      final results = await Future.wait([
        _powerAuth.hasValidActivation(),
        _powerAuth.canStartActivation(),
        _powerAuth.hasPendingActivation(),
        _powerAuth.getActivationIdentifier(),
        _powerAuth.getActivationFingerprint(),
        _powerAuth.hasBiometryFactor(),
        _powerAuth.getBiometryInfo(),
      ]);

      setState(() {
        _hasValidActivation = results[0] as bool?;
        _canStartActivation = results[1] as bool?;
        _hasPendingActivation = results[2] as bool?;
        _activationId = results[3] as String?;
        _activationFingerprint = results[4] as String?;
        _hasBiometryFactor = results[5] as bool?;
        _biometryInfo = results[6] as PowerAuthBiometryInfo?;
        _activationStatus = activationStatus;
      });

      print(
        'PowerAuth state refreshed successfully for instance: $_instanceId',
      );
    } on PowerAuthException catch (e) {
      _setError('Failed to refresh state: ${e.message} (${e.code})');
      setState(() {
        _hasValidActivation = null;
        _canStartActivation = null;
        _hasPendingActivation = null;
        _activationId = null;
        _activationFingerprint = null;
        _hasBiometryFactor = null;
        _biometryInfo = null;
        _activationStatus = null;
      });
    } catch (e) {
      _setError('An unexpected error occurred during state refresh: $e');
      setState(() {
        _hasValidActivation = null;
        _canStartActivation = null;
        _hasPendingActivation = null;
        _activationId = null;
        _activationFingerprint = null;
        _hasBiometryFactor = null;
        _biometryInfo = null;
        _activationStatus = null;
      });
    }
    _setLoading(false);
  }

  Future<void> _setInstanceId(String newInstanceId) async {
    if (_instanceId == newInstanceId) return;

    setState(() {
      _instanceId = newInstanceId;
      _powerAuth = PowerAuth(_instanceId);

      _isLoading = false;
      _isInitialized = false;
      _errorMessage = null;
      _isConfigured = false;
      _hasValidActivation = null;
      _canStartActivation = null;
      _hasPendingActivation = null;
      _activationId = null;
      _activationFingerprint = null;
      _activationStatus = null;
      _hasBiometryFactor = null;
      _biometryInfo = null;
    });
  }

  Future<void> _createActivationWithCode(
    String activationCode,
    String name,
  ) async {
    if (!_isConfigured) return _setError('Instance not configured');

    _setLoading(true);
    try {
      final activation = PowerAuthActivation.fromActivationCode(
        activationCode: activationCode,
        name: name,
      );
      final result = await _powerAuth.createActivation(activation);
      print('Activation created: ${result.activationFingerprint}');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError('Activation creation failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during activation creation: $e');
    }
    _setLoading(false);
  }

  Future<void> _persistActivationWithPassword(PowerAuthPassword password) async {
    if (!_isConfigured) return _setError('Instance not configured');
    if (_hasPendingActivation != true) return _setError('No pending activation to persist');

    _setLoading(true);
    try {
      final authentication = PowerAuthAuthentication.persistWithPassword(
        password,
      );
      await _powerAuth.persistActivation(authentication);
      print('Activation persisted successfully.');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError(
        'Activation persist failed: ${e.message} (${e.code}), ${e.toString()}',
      );
    } catch (e) {
      _setError('Unexpected error during activation persist: $e');
    }
    _setLoading(false);
  }

  Future<void> _persistActivationWithPasswordAndBiometry(PowerAuthPassword password) async {
    if (!_isConfigured) return _setError('Instance not configured');
    if (_hasPendingActivation != true) return _setError('No pending activation to persist');

    _setLoading(true);
    try {
      final prompt = PowerAuthBiometricPrompt(
        promptTitle: "Persist Activation",
        promptMessage: "Please confirm activation persistence with biometry.",
      );

      final authentication =
          PowerAuthAuthentication.persistWithPasswordAndBiometry(
            password: password,
            biometricPrompt: prompt,
          );

      await _powerAuth.persistActivation(authentication);
      print('Activation persisted successfully with Password + Biometry.');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError(
        'Activation persist (Bio) failed: ${e.message} (${e.code}), ${e.toString()}',
      );
    } catch (e) {
      _setError('Unexpected error during activation persist (Bio): $e');
    }
    _setLoading(false);
  }

  Future<void> _removeActivationWithPassword(PowerAuthPassword password) async {
    if (!_isConfigured) return _setError('Instance not configured');
    if (_hasValidActivation != true) return _setError('No active activation to remove');

    _setLoading(true);
    try {
      final authentication = PowerAuthAuthentication.password(password);
      await _powerAuth.removeActivationWithAuthentication(authentication);

      print('Activation removed successfully.');
      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError('Activation removal failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during activation removal: $e');
    }
    _setLoading(false);
  }

  Future<void> _removeActivationWithBiometry() async {
    if (!_isConfigured) return _setError('Instance not configured');
    if (_hasValidActivation != true) return _setError('No active activation to remove');

    _setLoading(true);
    try {
      final prompt = PowerAuthBiometricPrompt(
        promptTitle: "Remove Activation",
        promptMessage: "Please confirm activation removal with biometry.",
      );

      final authentication = PowerAuthAuthentication.biometry(
        biometricPrompt: prompt,
      );

      await _powerAuth.removeActivationWithAuthentication(authentication);
      print('Activation removed successfully with biometry.');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError('Activation removal (Bio) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during activation removal (Bio): $e');
    }
    _setLoading(false);
  }

  Future<void> _removeActivationLocal() async {
    if (!_isConfigured) return _setError('Instance not configured');

    _setLoading(true);
    try {
      await _powerAuth.removeActivationLocal();
      print('Local activation removed successfully.');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError('Local activation removal failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during local activation removal: $e');
    }
    _setLoading(false);
  }

  Future<void> _validatePassword(String password) async {
    if (!_isConfigured || _hasValidActivation != true)
      return _setError('Instance not configured or no valid activation');

    _setLoading(true);
    try {
      final paPassword = await PowerAuthPassword.fromString(password);
      await _powerAuth.validatePassword(paPassword);
      print('Password validation successful.');

      // TODO: temporarily using the error banner as a success also...
      _setError('Password is valid.');
    } on PowerAuthException catch (e) {
      _setError('Password validation failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during password validation: $e');
    }
    _setLoading(false);
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    if (!_isConfigured || _hasValidActivation != true)
      return _setError('Instance not configured or no valid activation');

    _setLoading(true);
    try {
      final oldPaPassword = await PowerAuthPassword.fromString(oldPassword);
      final newPaPassword = await PowerAuthPassword.fromString(newPassword);

      await _powerAuth.changePassword(oldPaPassword, newPaPassword);
      print('Password changed successfully (online).');

      _setError('Password changed successfully.');
    } on PowerAuthException catch (e) {
      _setError('Password change failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during password change: $e');
    }
    _setLoading(false);
  }

  Future<void> _verifyServerSignedData(
    String data,
    String signature,
    bool useMasterKey,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');

    _setLoading(true);
    try {
      final isValid = await _powerAuth.verifyServerSignedData(
        data,
        signature,
        useMasterKey,
      );
      print('Server signature verification result: $isValid');

      // TODO: temporarily using the error banner as a success also...
      _setError('Server Signature Verified: $isValid');
    } on PowerAuthException catch (e) {
      _setError(
        'Server signature verification failed: ${e.message} (${e.code})',
      );
    } catch (e) {
      _setError('Unexpected error during server signature verification: $e');
    }
    _setLoading(false);
  }

  void _setLoading(bool loading) {
    if (!mounted) return;

    setState(() {
      _isLoading = loading;
      if (loading) {
        _errorMessage = null;
      }
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = null;
      });
    }
  }

  void _setError(String message) {
    print(message);

    if (!mounted) return;

    setState(() {
      _errorMessage = message;
    });
  }

  void _runTests() async {
    Tests().run();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PowerAuth Testing App'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            const Text('Automatic tests:'),
            ElevatedButton(
              onPressed: () => _runTests(),
              child: const Text('Run test'),
            ),
            const SizedBox(height: 12),
            const Text('Manual testing:'),

            _buildInstanceSelector(),

            const SizedBox(height: 10),

            if (_errorMessage != null)
              _buildErrorBanner(_errorMessage!, _clearError),
            const SizedBox(height: 10),

            if (!_isInitialized)
              ElevatedButton(
                onPressed: _isLoading ? null : _initializeAndRefresh,
                child: const Text('Initialize SDK'),
              )
            else ...[
              Text(
                'Activation Status',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),

              if (_isConfigured && !_isLoading)
                _buildStatusInfo()
              else if (_isLoading)
                const Center(child: Text('Loading status...'))
              else if (!_isConfigured && !AppConfig.isConfigMissing())
                const Text(
                  'Instance is not configured or the .env config is broken!',
                )
              else
                const Text(
                  'PowerAuth instance is not configured. Please check .env file.',
                  style: TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isLoading ? null : _refreshState,
                child: const Text('Refresh Status'),
              ),
              const SizedBox(height: 20),

              Text(
                'Activation Management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildActivationButtons(),
              const SizedBox(height: 20),

              Text(
                'Biometry Management', // New Section
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildBiometryButtons(), // New Buttons
              const SizedBox(height: 20),

              Text(
                'Password Stuff',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildPasswordButtons(),
              const SizedBox(height: 20),

              Text(
                'Signatures & Other',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildSignatureButtons(),
              const SizedBox(height: 20),

              // Validation Section
              Text(
                'Validation Utilities',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              _buildValidationButtons(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstanceSelector() {
    return DropdownButton<String>(
      value: _instanceId,
      hint: const Text("Select PowerAuth Instance"),
      onChanged:
          _isLoading
              ? null
              : (String? newValue) {
                if (newValue != null) {
                  _setInstanceId(newValue);
                }
              },
      items:
          // TODO: bring this into state / .env?
          <String>[
            'dev',
            'testID2',
            'invalid-instance',
          ].map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
    );
  }

  Widget _buildErrorBanner(String message, VoidCallback onDismiss) {
    return MaterialBanner(
      padding: const EdgeInsets.all(12),
      content: Text(message, style: const TextStyle(color: Colors.white)),
      leading: const Icon(Icons.error_outline, color: Colors.white),
      backgroundColor: Colors.redAccent,
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildStatusInfo() {
    String formatBool(bool? b) => b == null ? 'Unknown' : b.toString();

    String formatStatus(PowerAuthActivationStatus? status) {
      if (status == null) return 'Unknown';
      final name = status.state.name;
      if (status.state == PowerAuthActivationState.active) {
        return '$name (${status.remainingAttempts} auth. attempts left)';
      }
      return name;
    }
        

    String formatBiometryType(PowerAuthBiometryInfo? info) =>
        info?.biometryType.name ?? 'Unknown';

    String formatBiometryStatus(PowerAuthBiometryInfo? info) =>
        info?.canAuthenticate.name ?? 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instance ID: $_instanceId'),
        Text('Is Initialized: $_isInitialized'),
        Text('Is Configured: ${formatBool(_isConfigured)}'),
        Text('Has Valid Activation: ${formatBool(_hasValidActivation)}'),
        Text('Can Start Activation: ${formatBool(_canStartActivation)}'),
        Text('Has Pending Activation: ${formatBool(_hasPendingActivation)}'),
        Text('Activation ID: ${_activationId ?? "Unknown"}'),
        Text('Activation Fingerprint: ${_activationFingerprint ?? "Unknown"}'),
        Text('Activation Status: ${formatStatus(_activationStatus)}'),
        Text('Has Biometry Factor: ${formatBool(_hasBiometryFactor)}'),
        Text(
          'Biometry Info Available: ${formatBool(_biometryInfo?.isAvailable)}',
        ),
        Text('Biometry Info Type: ${formatBiometryType(_biometryInfo)}'),
        Text('Biometry Info Status: ${formatBiometryStatus(_biometryInfo)}'),
      ],
    );
  }

  Widget _buildActivationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasPendingActivation == true
                  ? null
                  : () => _showInputDialog(
                    context,
                    title: 'Create Activation',
                    label: 'Activation Code',
                    onSubmit: (code) {
                      _createActivationWithCode(code, 'flutter-test');
                    },
                  ),
          child: const Text('Create Activation (Code)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasPendingActivation != true
                  ? null
                  : () => _showInputDialog(
                    context,
                    title: 'Persist Activation (PWD)',
                    label: 'Password',
                    isPassword: true,
                    onSubmit: (password) async {
                      _persistActivationWithPassword(
                        await PowerAuthPassword.fromString(password),
                      );
                    },
                  ),
          child: const Text('Persist Activation (Password)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasPendingActivation != true
                  ? null
                  : () => _showInputDialog(
                    context,
                    title: 'Persist Activation (PWD+Bio)',
                    label: 'Password',
                    isPassword: true,
                    onSubmit: (password) async {
                      _persistActivationWithPasswordAndBiometry(
                        await PowerAuthPassword.fromString(password),
                      );
                    },
                  ),
          child: const Text('Persist Activation (Password+Bio)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showInputDialog(
                    context,
                    title: 'Remove Activation (PWD)',
                    label: 'Password',
                    isPassword: true,
                    onSubmit: (password) async {
                      _removeActivationWithPassword(
                        await PowerAuthPassword.fromString(password),
                      );
                    },
                  ),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
          child: const Text('Remove Activation (Password)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading ||
                      !_isConfigured ||
                      _hasValidActivation != true ||
                      _hasBiometryFactor != true
                  ? null
                  : () async {
                    _removeActivationWithBiometry();
                  },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[900]),
          child: const Text('Remove Activation (Biometry)'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured
                  ? null
                  : () async {
                    final confirm = await _showConfirmDialog(
                      context,
                      title: 'Remove Local Activation',
                      content:
                          'Are you sure you want to remove activation data locally? This cannot be undone and does not affect the server.',
                    );
                    if (confirm == true) {
                      _removeActivationLocal();
                    }
                  },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Remove Activation (Local Only)'),
        ),
      ],
    );
  }

  /// Builds the password operations buttons.
  Widget _buildPasswordButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showInputDialog(
                    context,
                    title: 'Validate Password',
                    label: 'Password',
                    isPassword: true,
                    onSubmit: (password) {
                      _validatePassword(password);
                    },
                  ),
          child: const Text('Validate Password'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showPasswordChangeDialog(
                    context,
                    title: 'Change Password (Online)',
                    onSubmit: (oldPass, newPass) {
                      _changePassword(oldPass, newPass);
                    },
                  ),
          child: const Text('Change Password (Online)'),
        ),
      ],
    );
  }

  /// Builds the signature operation buttons.
  Widget _buildSignatureButtons() {
    const defaultUriId = '/pa/signature/validate';
    const defaultData = 'e2pzb25ib2R5OiAieWVzIn0=';
    const defaultBody = '{jsonbody: "yes"}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute Offline Signature (PWD)',
                    fields: {'Password': true, 'URI ID': false, 'Data': false, 'Nonce': false},
                    initialValues: {
                      'URI ID': defaultUriId,
                      'Data': defaultData,
                      'Nonce': _generateRandomNonce(),
                    },
                    onSubmit: (values) {
                      _computeOfflineSignatureWithPassword(
                        values['Password']!,
                        values['URI ID']!,
                        values['Data']!,
                        values['Nonce']!,
                      );
                    },
                  ),
          child: const Text('Compute Offline Signature (PWD)'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading ||
                      !_isConfigured ||
                      _hasValidActivation != true ||
                      _hasBiometryFactor != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute Offline Signature (Bio)',
                    fields: {'URI ID': false, 'Data': false, 'Nonce': false},
                    initialValues: {
                      'URI ID': defaultUriId,
                      'Data': defaultData,
                      'Nonce': _generateRandomNonce(),
                    },
                    onSubmit: (values) {
                      _computeOfflineSignatureWithBiometry(
                        values['URI ID']!,
                        values['Data']!,
                        values['Nonce']!,
                      );
                    },
                  ),
          child: const Text('Compute Offline Signature (Bio)'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Verify Server Signature',
                    fields: {'Data': false, 'Signature (Base64)': false},
                    onSubmit: (values) {
                      _verifyServerSignedData(
                        values['Data']!,
                        values['Signature (Base64)']!,
                        true,
                      );
                    },
                  ),
          child: const Text('Verify Server Signature'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute GET Signature Header (PWD)',
                    fields: {'Password': true, 'URI ID': false},
                    initialValues: {'URI ID': defaultUriId},
                    onSubmit: (values) {
                      _computeGetSignatureWithPassword(
                        values['Password']!,
                        values['URI ID']!,
                      );
                    },
                  ),
          child: const Text('Compute GET Signature Header (PWD)'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading ||
                      !_isConfigured ||
                      _hasValidActivation != true ||
                      _hasBiometryFactor != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute GET Signature Header (Bio)',
                    fields: {'URI ID': false},
                    initialValues: {'URI ID': defaultUriId},
                    onSubmit: (values) {
                      _computeGetSignatureWithBiometry(values['URI ID']!);
                    },
                  ),
          child: const Text('Compute GET Signature Header (Bio)'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasValidActivation != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute POST Signature Header (PWD)',
                    fields: {
                      'Password': true,
                      'URI ID': false,
                      'Request Body': false,
                    },
                    initialValues: {
                      'URI ID': defaultUriId,
                      'Request Body': defaultBody,
                    },
                    onSubmit: (values) {
                      _computePostSignatureWithPassword(
                        values['Password']!,
                        values['URI ID']!,
                        values['Request Body']!,
                      );
                    },
                  ),
          child: const Text('Compute POST Signature Header (PWD)'),
        ),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading ||
                      !_isConfigured ||
                      _hasValidActivation != true ||
                      _hasBiometryFactor != true
                  ? null
                  : () => _showSignatureInputDialog(
                    context,
                    title: 'Compute POST Signature Header (Bio)',
                    fields: {'URI ID': false, 'Request Body': false},
                    initialValues: {
                      'URI ID': defaultUriId,
                      'Request Body': defaultBody,
                    },
                    onSubmit: (values) {
                      _computePostSignatureWithBiometry(
                        values['URI ID']!,
                        values['Request Body']!,
                      );
                    },
                  ),
          child: const Text('Compute POST Signature Header (Bio)'),
        ),
      ],
    );
  }

  /// Builds the validation utility buttons.
  Widget _buildValidationButtons() {
    void showResultDialog(String title, String message) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed:
              () => _showInputDialog(
                context,
                title: 'Parse Activation Code',
                label: 'Activation Code',
                onSubmit: (code) async {
                  try {
                    final result =
                        await PowerAuthActivationCodeUtil.parseActivationCode(
                          code,
                        );
                    showResultDialog(
                      'Parsed Code',
                      'Code: ${result.activationCode}\nSignature: ${result.activationSignature}',
                    );
                  } catch (e) {
                    showResultDialog('Error', 'Failed to parse code: $e');
                  }
                },
              ),
          child: const Text('Parse Activation Code'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              () => _showInputDialog(
                context,
                title: 'Validate Activation Code',
                label: 'Activation Code (no signature)',
                onSubmit: (code) async {
                  try {
                    final isValid =
                        await PowerAuthActivationCodeUtil.validateActivationCode(
                          code,
                        );
                    showResultDialog('Validation Result', 'Is Valid: $isValid');
                  } catch (e) {
                    showResultDialog('Error', 'Validation failed: $e');
                  }
                },
              ),
          child: const Text('Validate Activation Code'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              () => _showInputDialog(
                context,
                title: 'Validate Typed Character',
                label: 'Enter ONE character',
                onSubmit: (char) async {
                  if (char.length != 1) {
                    showResultDialog(
                      'Error',
                      'Please enter exactly one character.',
                    );
                    return;
                  }
                  try {
                    final isValid =
                        await PowerAuthActivationCodeUtil.validateTypedCharacter(
                          char.codeUnitAt(0),
                        );
                    showResultDialog(
                      'Validation Result',
                      'Is Valid Character: $isValid',
                    );
                  } catch (e) {
                    showResultDialog('Error', 'Validation failed: $e');
                  }
                },
              ),
          child: const Text('Validate Typed Character'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              () => _showInputDialog(
                context,
                title: 'Correct Typed Character',
                label: 'Enter ONE character (e.g., 0, 1, a)',
                onSubmit: (char) async {
                  if (char.length != 1) {
                    showResultDialog(
                      'Error',
                      'Please enter exactly one character.',
                    );
                    return;
                  }
                  try {
                    final correctedCodePoint =
                        await PowerAuthActivationCodeUtil.correctTypedCharacter(
                          char.codeUnitAt(0),
                        );
                    final correctedChar = String.fromCharCode(
                      correctedCodePoint,
                    );
                    showResultDialog(
                      'Correction Result',
                      'Corrected Character: $correctedChar (Code: $correctedCodePoint)',
                    );
                  } catch (e) {
                    if (e is PowerAuthException &&
                        e.code == PowerAuthErrorCode.invalidCharacter) {
                      showResultDialog(
                        'Correction Result',
                        'Character \'$char\' is invalid and cannot be corrected.',
                      );
                    } else {
                      showResultDialog('Error', 'Correction failed: $e');
                    }
                  }
                },
              ),
          child: const Text('Correct Typed Character'),
        ),
      ],
    );
  }

  Future<void> _showInputDialog(
    BuildContext context, {
    required String title,
    required String label,
    bool isPassword = false,
    required Function(String) onSubmit,
  }) async {
    final controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(labelText: label),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final value = controller.text;
                Navigator.of(dialogContext).pop();
                if (value.isNotEmpty) {
                  onSubmit(value);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPasswordChangeDialog(
    BuildContext context, {
    required String title,
    required Function(String, String) onSubmit,
  }) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final oldPassword = oldPasswordController.text;
                final newPassword = newPasswordController.text;
                Navigator.of(dialogContext).pop();
                if (oldPassword.isNotEmpty && newPassword.isNotEmpty) {
                  onSubmit(oldPassword, newPassword);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSignatureInputDialog(
    BuildContext context, {
    required String title,
    required Map<String, bool> fields,
    Map<String, String>? initialValues,
    required Function(Map<String, String>) onSubmit,
  }) async {
    final controllers = {
      for (var label in fields.keys)
        label: TextEditingController(text: initialValues?[label] ?? ''),
    };

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  fields.entries.map((entry) {
                    final label = entry.key;
                    final isPassword = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: controllers[label],
                        obscureText: isPassword,
                        decoration: InputDecoration(labelText: label),
                        autofocus: fields.keys.first == label,
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                final values = controllers.map(
                  (key, value) => MapEntry(key, value.text),
                );
                if (values.values.any((text) => text.isEmpty)) {
                  print("All fields are required.");
                  return;
                }
                Navigator.of(dialogContext).pop();
                onSubmit(values);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBiometryButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed:
              _isLoading ||
                      !_isConfigured ||
                      _hasValidActivation != true ||
                      _hasBiometryFactor == true
                  ? null
                  : _addBiometryFactor,
          child: const Text('Add Biometry Factor'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed:
              _isLoading || !_isConfigured || _hasBiometryFactor != true
                  ? null
                  : _removeBiometryFactor,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
          child: const Text('Remove Biometry Factor'),
        ),
      ],
    );
  }

  Future<void> _addBiometryFactor() async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    if (_hasBiometryFactor == true) return _setError('Biometry factor already added');

    await _showInputDialog(
      context,
      title: 'Add Biometry Factor',
      label: 'Password',
      isPassword: true,
      onSubmit: (password) async {
        _setLoading(true);

        try {
          final paPassword = await PowerAuthPassword.fromString(password);
          final prompt = PowerAuthBiometricPrompt(
            promptTitle: "Add Biometry",
            promptMessage: "Please authenticate to add biometry.",
          );

          await _powerAuth.addBiometryFactor(paPassword, prompt);
          print('Biometry factor added successfully.');
          _setError('Biometry factor added.');

          await _refreshState();
        } on PowerAuthException catch (e) {
          _setError('Adding biometry factor failed: ${e.message} (${e.code})');
        } catch (e) {
          _setError('Unexpected error adding biometry factor: $e');
        }
        _setLoading(false);
      },
    );
  }

  Future<void> _removeBiometryFactor() async {
    if (!_isConfigured || _hasBiometryFactor != true) {
      return _setError(
        'Instance not configured or no biometry factor to remove',
      );
    }

    final confirm = await _showConfirmDialog(
      context,
      title: 'Remove Biometry Factor',
      content: 'Are you sure you want to remove the biometry factor? This cannot be undone.',
    );

    if (confirm != true) return;

    _setLoading(true);
    try {
      await _powerAuth.removeBiometryFactor();
      print('Biometry factor removed successfully.');
      _setError('Biometry factor removed.');

      await _refreshState();
    } on PowerAuthException catch (e) {
      _setError('Removing biometry factor failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error removing biometry factor: $e');
    }
    _setLoading(false);
  }

  Future<void> _computeOfflineSignatureWithPassword(
    String password,
    String uriId,
    String data,
    String nonce,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    _setLoading(true);

    final fixedData = data.replaceAll("\\n", "\n");

    try {
      final paPassword = await PowerAuthPassword.fromString(password);
      final authentication = PowerAuthAuthentication.password(paPassword);

      final signature = await _powerAuth.offlineSignature(
        authentication,
        uriId,
        nonce,
        fixedData,
      );

      print('Offline signature (PWD) computed: $signature');
      _setError('Offline Signature (PWD): $signature');
    } on PowerAuthException catch (e) {
      _setError('Offline signature (PWD) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during offline signature (PWD): $e');
    }
    _setLoading(false);
  }

  Future<void> _computeOfflineSignatureWithBiometry(
    String uriId,
    String data,
    String nonce,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    if (_hasBiometryFactor != true)
      return _setError('Biometry factor not available');

    _setLoading(true);
    final fixedData = data.replaceAll("\\n", "\n");
    try {
      final prompt = PowerAuthBiometricPrompt(
        promptTitle: "Offline Signature",
        promptMessage: "Authenticate for offline signature.",
      );

      final authentication = PowerAuthAuthentication.biometry(
        biometricPrompt: prompt,
      );

      final signature = await _powerAuth.offlineSignature(
        authentication,
        uriId,
        nonce,
        fixedData,
      );

      print('Offline signature (Bio) computed: $signature');
      _setError('Offline Signature (Bio): $signature');
    } on PowerAuthException catch (e) {
      _setError('Offline signature (Bio) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during offline signature (Bio): $e');
    }
    _setLoading(false);
  }

  Future<void> _computeGetSignatureWithPassword(
    String password,
    String uriId,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    _setLoading(true);

    try {
      final paPassword = await PowerAuthPassword.fromString(password);
      final authentication = PowerAuthAuthentication.password(paPassword);

      final header = await _powerAuth.requestGetSignature(
        authentication,
        uriId,
      );

      print('GET Signature Header (PWD): ${header.key}: ${header.value}');
      _setError('GET Header (PWD): ${header.key}: ${header.value}');
    } on PowerAuthException catch (e) {
      _setError('GET signature (PWD) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during GET signature (PWD): $e');
    }
    _setLoading(false);
  }

  Future<void> _computeGetSignatureWithBiometry(String uriId) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    if (_hasBiometryFactor != true) return _setError('Biometry factor not available');

    _setLoading(true);
    try {
      final prompt = PowerAuthBiometricPrompt(
        promptTitle: "GET Signature",
        promptMessage: "Authenticate for GET signature.",
      );

      final authentication = PowerAuthAuthentication.biometry(
        biometricPrompt: prompt,
      );

      final header = await _powerAuth.requestGetSignature(
        authentication,
        uriId,
      );

      print('GET Signature Header (Bio): ${header.key}: ${header.value}');
      _setError('GET Header (Bio): ${header.key}: ${header.value}');
    } on PowerAuthException catch (e) {
      _setError('GET signature (Bio) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during GET signature (Bio): $e');
    }
    _setLoading(false);
  }

  Future<void> _computePostSignatureWithPassword(
    String password,
    String uriId,
    String body,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    _setLoading(true);

    try {
      final paPassword = await PowerAuthPassword.fromString(password);
      final authentication = PowerAuthAuthentication.password(paPassword);

      final header = await _powerAuth.requestSignature(
        authentication,
        'POST',
        uriId,
        body,
      );

      print('POST Signature Header (PWD): ${header.key}: ${header.value}');
      print('For payload: ${base64Encode(utf8.encode(body))}');
      _setError('POST Header (PWD): ${header.key}: ${header.value}');
    } on PowerAuthException catch (e) {
      _setError('POST signature (PWD) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during POST signature (PWD): $e');
    }
    _setLoading(false);
  }

  Future<void> _computePostSignatureWithBiometry(
    String uriId,
    String body,
  ) async {
    if (!_isConfigured || _hasValidActivation != true) return _setError('Instance not configured or no valid activation');
    if (_hasBiometryFactor != true) return _setError('Biometry factor not available');

    _setLoading(true);

    try {
      final prompt = PowerAuthBiometricPrompt(
        promptTitle: "POST Signature",
        promptMessage: "Authenticate for POST signature.",
      );

      final authentication = PowerAuthAuthentication.biometry(
        biometricPrompt: prompt,
      );

      final header = await _powerAuth.requestSignature(
        authentication,
        'POST',
        uriId,
        body,
      );

      print('POST Signature Header (Bio): ${header.key}: ${header.value}');
      print('For payload: ${base64Encode(utf8.encode(body))}');
      _setError('POST Header (Bio): ${header.key}: ${header.value}');
    } on PowerAuthException catch (e) {
      _setError('POST signature (Bio) failed: ${e.message} (${e.code})');
    } catch (e) {
      _setError('Unexpected error during POST signature (Bio): $e');
    }
    _setLoading(false);
  }
}
