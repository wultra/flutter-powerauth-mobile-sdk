import Flutter
import UIKit
import PowerAuth2
import PowerAuthCore

public class PowerAuthPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "powerauth_plugin", binaryMessenger: registrar.messenger())
        let instance = PowerAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        // Similarly to CDV, args are passed as part of the `FlutterMethodCall` object
        guard let arguments = call.arguments as? [String: Any] else {
            // Error here
            return
        }

        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
