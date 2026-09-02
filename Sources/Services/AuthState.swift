import Foundation
import Observation

/// Local-only profile state. DurBi has no backend, so Sign in with Apple / Google here just
/// personalizes the Settings screen (name shown, a sense of "this is my account") — it does not
/// gate any feature or sync anything server-side. Persisted in plain UserDefaults since it never
/// needs to be visible to the extensions.
@Observable
final class AuthState {
    static let shared = AuthState()

    private(set) var provider: String?
    private(set) var displayName: String?
    private(set) var email: String?

    var isSignedIn: Bool { provider != nil }

    private init() {
        provider = UserDefaults.standard.string(forKey: "auth.provider")
        displayName = UserDefaults.standard.string(forKey: "auth.displayName")
        email = UserDefaults.standard.string(forKey: "auth.email")
    }

    func signIn(provider: String, displayName: String?, email: String?) {
        self.provider = provider
        if let displayName, !displayName.isEmpty {
            self.displayName = displayName
        }
        if let email {
            self.email = email
        }
        UserDefaults.standard.set(self.provider, forKey: "auth.provider")
        UserDefaults.standard.set(self.displayName, forKey: "auth.displayName")
        UserDefaults.standard.set(self.email, forKey: "auth.email")
    }

    func signOut() {
        clearLocalProfile()
    }

    /// Apple App Review Guideline 5.1.1(v): an app that supports account creation must offer
    /// account deletion, not just sign-out/deactivation. DurBi has no backend account — the
    /// Apple/Google sign-in above only ever wrote this locally-cached name/email/provider — so
    /// deleting it here, immediately and permanently, IS the complete account deletion; there is
    /// no server-side record left behind anywhere.
    func deleteAccount() {
        clearLocalProfile()
    }

    private func clearLocalProfile() {
        provider = nil
        displayName = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: "auth.provider")
        UserDefaults.standard.removeObject(forKey: "auth.displayName")
        UserDefaults.standard.removeObject(forKey: "auth.email")
    }
}
