import Flutter
import UIKit
import receive_sharing_intent

// Adopts UISceneDelegate as required by upcoming iOS versions.
// See: https://docs.flutter.dev/release/breaking-changes/uiscenedelegate
//
class SceneDelegate: FlutterSceneDelegate {

    // Called on a cold start when the scene connects. The shared URL (if any)
    // is delivered here via connectionOptions instead of the launchOptions.
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Work-around to prevent other libraries like flutter_branch_sdk from absorbing links meant to be handled by receive_sharing_intent.
        _ = ReceiveSharingIntentPlugin.instance.scene(scene, willConnectTo: session, options: connectionOptions)
        super.scene(scene, willConnectTo: session, options: connectionOptions)
    }

    // Called while the app is already running (warm start).
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Work-around to prevent other libraries like flutter_branch_sdk from absorbing links meant to be handled by receive_sharing_intent.
        if ReceiveSharingIntentPlugin.instance.scene(scene, openURLContexts: URLContexts) {
            return
        }
        // Proceed url handling for other Flutter libraries like uni_links
        super.scene(scene, openURLContexts: URLContexts)
    }
}


