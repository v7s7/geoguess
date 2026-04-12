import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure AVAudioSession BEFORE Flutter engine starts so that the
    // audioplayers plugin finds a properly initialised audio session on iOS.
    // .ambient lets other apps (Music, Podcasts) keep playing alongside
    // game sounds; use .playback instead if exclusive audio is needed.
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .ambient,
        mode: .default,
        options: [.mixWithOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      // Non-fatal — the app still works without audio.
      print("[GeoGuess] AVAudioSession setup failed: \(error)")
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
