import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Match window background to Flutter startup screen color to avoid black flash
    window?.backgroundColor = UIColor(red: 79/255, green: 70/255, blue: 229/255, alpha: 1)
  }
}
