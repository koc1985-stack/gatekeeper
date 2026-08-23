import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// Optional profile section for Settings. Sign in with Apple / Google here is purely local —
/// DurBi has no backend to verify against — it just personalizes the screen with a name/email
/// and gives the user a "sign out" affordance. See AuthState for the persistence.
struct ProfileSection: View {
    @State private var authState = AuthState.shared
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        Section("Profil") {
            if authState.isSignedIn {
                VStack(alignment: .leading, spacing: 4) {
                    Text(authState.displayName?.isEmpty == false ? authState.displayName! : "Hesabım")
                        .font(.body)
                    if let email = authState.email, !email.isEmpty {
                        Text(email)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("Çıkış Yap", role: .destructive) {
                    authState.signOut()
                }
            } else {
                if isSigningIn {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 44)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, 16)

                    if GoogleSignInSupport.isConfigured {
                        Button {
                            handleGoogleSignIn()
                        } label: {
                            Label("Google ile Giriş Yap", systemImage: "g.circle.fill")
                        }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Beklenmeyen bir hata oluştu."
                return
            }
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            errorMessage = nil
            authState.signIn(
                provider: "apple",
                displayName: fullName.isEmpty ? nil : fullName,
                email: credential.email
            )
        }
    }

    private func handleGoogleSignIn() {
        guard let presentingVC = GoogleSignInSupport.topmostViewController() else { return }
        isSigningIn = true
        errorMessage = nil
        Task {
            defer { isSigningIn = false }
            do {
                let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                    GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC) { signInResult, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let signInResult {
                            continuation.resume(returning: signInResult)
                        } else {
                            continuation.resume(throwing: URLError(.unknown))
                        }
                    }
                }
                authState.signIn(
                    provider: "google",
                    displayName: result.user.profile?.name,
                    email: result.user.profile?.email
                )
            } catch {
                let nsError = error as NSError
                if nsError.domain.contains("GIDSignIn") && nsError.code == -5 { return }
                errorMessage = error.localizedDescription
            }
        }
    }
}
