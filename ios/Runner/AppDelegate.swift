import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // GMSApiKey comes from ios/Flutter/Secrets.xcconfig via Info.plist.
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty, !key.hasPrefix("$(") {
      GMSServices.provideAPIKey(key)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Bundle id lets REST calls pass an iOS-app-restricted Google API key.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SunRouteAppIdentity") {
      let channel = FlutterMethodChannel(
        name: "sunroute/app_identity", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "getIdentity" {
          result(["bundleId": Bundle.main.bundleIdentifier ?? ""])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
