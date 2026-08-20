# PowerAuth Server Compatibility

This document describes the compatibility between the PowerAuth Mobile Flutter SDK and PowerAuth Server versions.

## Server Requirements

PowerAuth Mobile Flutter SDK 2.0 supports PowerAuth protocol 4.0 and legacy protocol 3.3. The server requirement depends on the configured algorithm:

- `PowerAuthAlgorithm.p384`, `p384l3`, and `p384l5` require PowerAuth Server version `2.0.0` or later.
- `PowerAuthAlgorithm.legacy` requires PowerAuth Server version `1.9.0` or later.

## Flutter SDK as a Wrapper

The PowerAuth Mobile Flutter SDK is a wrapper built on top of the native PowerAuth Mobile SDK. It provides a Flutter-friendly interface while leveraging the proven cryptographic implementations and network communication protocols of the underlying native SDK.

For more information about the native PowerAuth Mobile SDK, please refer to the [PowerAuth Mobile SDK repository](https://github.com/wultra/powerauth-mobile-sdk).

## Read Next

- [Installation](Installation.md)
