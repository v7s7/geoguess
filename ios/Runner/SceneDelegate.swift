import Flutter
import UIKit

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    applyOpaqueWhiteBackground(to: scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    applyOpaqueWhiteBackground(to: scene)
  }

  private func applyOpaqueWhiteBackground(to scene: UIScene) {
    guard let windowScene = scene as? UIWindowScene else { return }
    // Defer so the window and rootViewController are fully set up.
    // Use keyWindow (replaces deprecated windowScene.windows on iOS 15+).
    DispatchQueue.main.async {
      let window = windowScene.keyWindow ?? windowScene.windows.first
      window?.backgroundColor = UIColor.white
      if let view = window?.rootViewController?.view {
        view.backgroundColor = UIColor.white
        view.isOpaque = true
      }
    }
  }
}
