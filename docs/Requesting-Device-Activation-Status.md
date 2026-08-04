# Requesting Device Activation Status

To quickly determine in which state is the activation state, you need to fetch its status.


## Obtaining the Activation Status

To obtain detailed activation status information, use the following code:

```dart
// Check if there is some activation on the device
if (await powerAuth.hasValidActivation()) {

    try {
        // If there is an activation on the device, check the status with the server
        final status = await powerAuth.fetchActivationStatus();

        switch (status.state) {
            case PowerAuthActivationState.pendingCommit:
                // Activation is awaiting commit on the server.
                print("Waiting for commit");
            case PowerAuthActivationState.active:
                // Activation is valid and active.
                print("Activation is active");
            case PowerAuthActivationState.blocked:
                // Activation is blocked. You can display unblock
                // instructions to the user.
                print("Activation is blocked");
            case PowerAuthActivationState.removed:
                // Activation is no longer valid on the server.
                // You can inform the user about this situation and remove
                // activation locally via "await powerAuth.removeActivationLocal()"
                print("Activation is no longer valid");
            case PowerAuthActivationState.deadlock:
                // Local activation is technically blocked and no longer
                // can be used for the signature calculations. You can inform
                // user about this situation and remove activation locally
                // via "await powerAuth.removeActivationLocal()"
                print("Activation is technically blocked");
            case PowerAuthActivationState.unknown:
                // The server returned a state that this SDK does not know.
                // Do not treat this state as a removed activation.
                print("Activation state is unknown");
        }

        // Failed login attempts, remaining = max - current
        final currentFailCount = status.failCount;
        final maxAllowedFailCount = status.maxFailCount;
        final remainingFailCount = status.remainingAttempts;
        // Custom object contains any proprietary server-specific data
        final customObject = status.customObject;
    } catch (e) {
        print("An error occurred, report it to the user");
    }
} else {
  print("No activation present on device");
}
```

The status fetch can fail with the unrecoverable `PowerAuthErrorCode.protocolUpgrade` error. This error means that the SDK cannot upgrade the PowerAuth protocol. In this case, [remove the activation locally](Device-Activation-Removal.md).

## Authenticated Protocol Upgrade

The fetched activation status can show that a protocol upgrade is available. The upgrade requires the knowledge factor:

```dart
await powerAuth.fetchActivationStatus();

if (await powerAuth.hasProtocolUpgradeAvailable()) {
    final password = await PowerAuthPassword.fromString("1234");
    final result = await powerAuth.startProtocolUpgrade(password);

    if (result.activationStatusFetchRequired) {
        await powerAuth.fetchActivationStatus();
    }

    final upgradedFingerprint = result.activationFingerprint ??
        await powerAuth.getActivationFingerprint();
    // If your activation flow presents or records the activation fingerprint,
    // process the new fingerprint after the upgrade is complete.

    if (result.biometryFactorRemoved) {
        // Add the biometry factor again after the upgrade.
    }
}
```

On Android, set `upgradeBiometry` to `true` to migrate an existing biometry factor. This option works only when `authenticateOnBiometricKeySetup` is `false`. On iOS, the SDK preserves an existing biometry factor automatically.

When `activationStatusFetchRequired` is `false`, `result.activationFingerprint` contains the new fingerprint. When a status fetch is required, that result property is `null`; finish the upgrade and obtain the current value with `getActivationFingerprint()` instead.

If `hasPendingProtocolUpgrade()` returns `true`, call `fetchActivationStatus()` to finish the upgrade. Some SDK operations are not available while an upgrade is pending.

To get more information about activation states, check the [Activation States](https://github.com/wultra/powerauth-crypto/blob/develop/docs/Activation.md#activation-states) chapter available in our [powerauth-crypto](https://github.com/wultra/powerauth-crypto) repository.

## Read Next

- [Data Signing](Data-Signing.md)
