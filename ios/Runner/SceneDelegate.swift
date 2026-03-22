import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // Set the Flutter view's background to opaque white so that if Flutter's
    // Metal layer is transparent during any frame (e.g. during route transitions),
    // users see white instead of the system window background (which is black in
    // dark environments). Flutter's own Scaffold backgrounds paint on top of this.
    guard let windowScene = scene as? UIWindowScene else { return }
    let window = windowScene.windows.first
    window?.backgroundColor = UIColor.white
    window?.rootViewController?.view.backgroundColor = UIColor.white
  }
}
