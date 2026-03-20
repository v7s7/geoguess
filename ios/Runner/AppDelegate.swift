import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Prevent black window flash before Flutter renders its first frame.
    // The iOS UIWindow is black by default; setting it to match the app's
    // background colour ensures a seamless transition from the launch screen.
    window?.backgroundColor = UIColor(red: 13/255, green: 27/255, blue: 46/255, alpha: 1)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
