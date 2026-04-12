import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // FlutterSceneDelegate creates the UIWindow during super.scene(...).
    // Setting backgroundColor here (after super) ensures the indigo colour
    // shows through any transparent areas while the Flutter first frame is
    // being committed to Metal — preventing the brief black flash on iOS.
    window?.backgroundColor = UIColor(red: 79/255, green: 70/255, blue: 229/255, alpha: 1)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    // Re-apply after the scene becomes active in case the window was
    // recreated (e.g. after a split-screen transition on iPad).
    window?.backgroundColor = UIColor(red: 79/255, green: 70/255, blue: 229/255, alpha: 1)
  }
}
