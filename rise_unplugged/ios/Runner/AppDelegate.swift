import UIKit
import Flutter
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.rise.unplugged/timezone",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getLocalTimezone":
          result(TimeZone.autoupdatingCurrent.identifier)

        case "getAvailableTimezones":
          result(TimeZone.knownTimeZoneIdentifiers)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
