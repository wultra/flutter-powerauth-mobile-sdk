# PowerAuth Server Compatibility

This document describes the compatibility between the PowerAuth Mobile Flutter SDK and PowerAuth Server versions.

## Server Requirements

To use this Flutter SDK, your PowerAuth Server must be running version **1.9.0** or higher. The SDK is compatible with all PowerAuth Server versions 1.9.x and above.

## Flutter SDK as a Wrapper

The PowerAuth Mobile Flutter SDK is a wrapper built on top of the native PowerAuth Mobile SDK. It provides a Flutter-friendly interface while leveraging the proven cryptographic implementations and network communication protocols of the underlying native SDK.

For more information about the native PowerAuth Mobile SDK, please refer to the [PowerAuth Mobile SDK repository](https://github.com/wultra/powerauth-mobile-sdk).

## Compatibility Table

| Flutter SDK Version | Native SDK   | Server version |
|---------------------|--------------|----------------|
| `1.3.x`             | `1.9.x`      | `1.9.+`        |
| `1.2.x`             | `1.9.x`      | `1.9.+`        |
| `1.1.x`             | `1.9.x`      | `1.9.+`        |
| `1.0.x`             | `1.9.x`      | `1.9.+`        |

## Read Next

- [Installation](Installation.md)