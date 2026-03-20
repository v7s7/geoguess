import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Match the app's startup screen background before Flutter's first frame renders.
    guard let windowScene = scene as? UIWindowScene else { return }
    windowScene.windows.first?.backgroundColor = UIColor(
      red: 13 / 255, green: 27 / 255, blue: 46 / 255, alpha: 1
    )
  }
}
