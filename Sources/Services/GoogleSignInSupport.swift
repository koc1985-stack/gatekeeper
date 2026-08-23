import GoogleSignIn
import UIKit

/// Small helpers around the Google Sign-In SDK, mirroring the same pattern used in the
/// Kozmika app: if a real GIDClientID hasn't been configured yet in project.yml (Google Cloud
/// Console → OAuth client for this bundle ID), the Google button simply doesn't appear instead
/// of failing confusingly when tapped.
enum GoogleSignInSupport {
    static var isConfigured: Bool {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else { return false }
        return !clientID.isEmpty && !clientID.contains("REPLACE_WITH_YOUR")
    }

    @MainActor
    static func topmostViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
