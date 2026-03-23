import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Set window background to the Flutter startup screen color so there is no
    // black flash between the native launch screen and Flutter's first frame.
    window?.backgroundColor = UIColor(red: 79/255, green: 70/255, blue: 229/255, alpha: 1)
  }
}
