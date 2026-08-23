import AppTrackingTransparency
import GoogleMobileAds
import UIKit

/// Ad infrastructure helpers: SDK startup + App Tracking Transparency (ATT). If ATT is denied,
/// the app keeps working fine — AdMob automatically falls back to non-personalized ads, that's
/// not an error condition we need to handle specially.
enum AdsSupport {
    /// Real DurBi banner ad unit (admob.google.com → DurBi → Ad units → Home Banner).
    static let bannerAdUnitID = "ca-app-pub-7881130184412841/1800299223"

    /// Called once at app launch (see ImpulseGatekeeperApp.init).
    static func startMobileAds() {
        MobileAds.shared.start()
    }

    /// Asks for tracking permission once, with a short delay (Apple's guidance: don't prompt
    /// the instant the app opens, wait until the user has settled in) — never asks twice.
    @MainActor
    static func requestTrackingPermissionIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                ATTrackingManager.requestTrackingAuthorization { _ in
                    continuation.resume()
                }
            }
        }
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
