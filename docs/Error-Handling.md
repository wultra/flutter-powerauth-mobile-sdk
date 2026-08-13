# Error Handling

Asynchronous PowerAuth operations report failures as `PowerAuthException`. Handle the stable `code` value in application logic. Treat `message` and `cause` as diagnostic information; their values may differ between Android and iOS and may change between operating-system versions.

```dart
try {
    await powerAuth.fetchActivationStatus();
} on PowerAuthException catch (e) {
    switch (e.code) {
        case PowerAuthErrorCode.networkError:
            // Offer a retry when appropriate.
            break;
        case PowerAuthErrorCode.protocolUpgrade:
            // The activation cannot be upgraded automatically.
            await powerAuth.removeActivationLocal();
            break;
        default:
            // Log diagnostics and handle the operation-specific failure.
            break;
    }
}
```

## Server and Transport Errors

`PowerAuthErrorCode.networkError` covers connectivity failures and failed HTTP requests. When the server returned a response, `PowerAuthException.errorData` can contain stable response details:

- `httpStatusCode`
- `responseBody`
- `serverResponseCode`, when provided by the server
- `serverResponseMessage`, when provided by the server

```dart
try {
    await powerAuth.fetchActivationStatus();
} on PowerAuthException catch (e) {
    if (e.code == PowerAuthErrorCode.networkError) {
        final status = e.errorData?["httpStatusCode"];
        final serverCode = e.errorData?["serverResponseCode"];
        print("PowerAuth request failed: HTTP $status, code $serverCode");
    }
}
```

Do not parse localized exception messages. Do not assume that every network error contains an HTTP response; offline requests and connection failures do not.

## Errors Requiring Application Action

| Error code | Recommended action |
|---|---|
| `biometryCancel` | Treat the cancellation as a normal user decision. |
| `biometryFallback` | On iOS, show the application's password or PIN flow. |
| `biometryNotAvailable`, `biometryNotEnrolled`, `biometryLockout` | Explain the system state and offer knowledge-factor authentication. |
| `wrongSignature` | Reject the received data. Do not retry verification as a network operation. |
| `pendingProtocolUpgrade` | Call `fetchActivationStatus()` to finish the upgrade, then retry the original operation. |
| `protocolUpgrade` | The status fetch could not upgrade the activation. Inform the user and remove the activation locally. |
| `upgradeSdk` | Update the application to a newer SDK. Do not delete activation data as recovery. |
| `externalPendingOperation` | On iOS, use `getExternalPendingOperation()` to identify the application performing the exclusive operation. |
| `invalidNativeObject` | Create or acquire a new password, encryptor, password-change data, or Secure Vault object. |
| `timeSynchronization` | Synchronize time again and retry only when the original operation is safe to repeat. |

`invalidActivationState`, `missingActivation`, `pendingActivation`, and `wrongParameter` normally indicate that application logic invoked an operation in the wrong state. Correct the flow instead of presenting these as generic connectivity failures.

## Configuration Failures

If `configure()` reports `invalidActivationData`, the stored data has an incompatible format. Call `cleanupInstanceData()` only with the same configuration values and only after this error, then configure the instance again.

If configuration reports `upgradeSdk`, install a newer SDK. Do not call `cleanupInstanceData()`, because the activation may be readable by the newer SDK.

See [Configuration Recovery](Configuration.md#configuration-recovery) for the complete example.

## Authentication Failure and Activation Status

Do not add a separate password-validation request before an authenticated operation. Perform the required operation and process its result. After an authentication failure, call `fetchActivationStatus()` before showing the number of remaining attempts or deciding whether the activation is blocked.

Do not submit another authenticated request with reusable biometric credentials after an HTTP 401 response. Repeating the request can increase the failed-attempt counter and block the activation.

## Platform Differences

The wrapper keeps native error codes whenever the native SDK provides them, so Android and iOS can occasionally reject locally invalid input with different but related codes. Application logic should rely on the documented operation contract and exact error code, but shared tests may need an explicit platform branch for a known native difference.

For the native error contracts, see [Android Error Handling](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-Android#error-handling) and [iOS Error Handling](https://developers.wultra.com/components/powerauth-mobile-sdk/develop/documentation/PowerAuth-SDK-for-iOS#error-handling).

## Read Next

- [Troubleshooting](Troubleshooting.md)
- [Logging](Logging.md)
