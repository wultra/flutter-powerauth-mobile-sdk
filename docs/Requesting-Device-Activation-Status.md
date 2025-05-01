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
            case PowerAuthActivationState.created:
                // Activation has just been created. This is the internal
                // state on the server and therefore can be ignored
                // on the mobile application.
                print("Activation was created");
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

Note that the status fetch may fail at an unrecoverable error `PowerAuthErrorCode.protocolUpgrade`, meaning that it's not possible to upgrade the PowerAuth protocol to a newer version. In this case, it's recommended to [remove the activation locally](Device-Activation-Removal.md).

To get more information about activation states, check the [Activation States](https://github.com/wultra/powerauth-crypto/blob/develop/docs/Activation.md#activation-states) chapter available in our [powerauth-crypto](https://github.com/wultra/powerauth-crypto) repository.

## Read Next

- [Data Signing](Data-Signing.md)
