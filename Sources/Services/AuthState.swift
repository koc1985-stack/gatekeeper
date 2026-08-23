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
        provider = nil
        displayName = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: "auth.provider")
        UserDefaults.standard.removeObject(forKey: "auth.displayName")
        UserDefaults.standard.removeObject(forKey: "auth.email")
    }
}
