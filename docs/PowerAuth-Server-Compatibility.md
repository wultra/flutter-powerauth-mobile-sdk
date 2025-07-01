# PowerAuth Server Compatibility

This document describes the compatibility between the PowerAuth Mobile Flutter SDK and PowerAuth Server versions.

## Flutter SDK as a Wrapper

The PowerAuth Mobile Flutter SDK is a wrapper built on top of the native PowerAuth Mobile SDK. It provides a Flutter-friendly interface while leveraging the proven cryptographic implementations and network communication protocols of the underlying native SDK.

For more information about the native PowerAuth Mobile SDK, please refer to the [PowerAuth Mobile SDK repository](https://github.com/wultra/powerauth-mobile-sdk).

## Current Version Compatibility

The current version of the PowerAuth Mobile Flutter SDK includes:

- **Native SDK Version**: 1.9.4
- **Required Server Version**: 1.9.0 or higher

### Version Details

- **iOS**: Uses PowerAuth2 framework version 1.9.4
- **Android**: Uses PowerAuth SDK version 1.9.4

## Server Requirements

To use this Flutter SDK, your PowerAuth Server must be running version **1.9.0** or higher. The SDK is compatible with all PowerAuth Server versions 1.9.x and above.

## Migration Notes

When upgrading between major versions of the Flutter SDK, the underlying native SDK version may also change. Always check this compatibility documentation to ensure your PowerAuth Server version supports the native SDK version included in your Flutter SDK version.

For detailed information about native SDK compatibility with specific server versions, please refer to the [native PowerAuth Mobile SDK documentation](https://github.com/wultra/powerauth-mobile-sdk).

## Read Next

- [Configuration](Configuration.md)
- [Installation](Installation.md)
- [Troubleshooting](Troubleshooting.md)