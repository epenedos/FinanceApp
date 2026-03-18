import Foundation
import AuthenticationServices
import Supabase
import Observation
import CryptoKit

// MARK: - Authentication Manager

/// Manages Supabase authentication with Apple Sign-In.
/// Exposes the current user session so the UI can gate access
/// and the SyncEngine can attach user_id to records.
@Observable
@MainActor
final class AuthManager {

    // MARK: - Properties

    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool = false
    private(set) var isLoading: Bool = true
    private(set) var errorMessage: String?

    private let client = SupabaseManager.client

    /// The current nonce used for Apple Sign-In (needed for token validation)
    private var currentNonce: String?

    // MARK: - Computed

    var userId: UUID? {
        currentUser?.id
    }

    // MARK: - Session Restoration

    /// Call on app launch to restore an existing session.
    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await client.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            // No existing session — user needs to sign in
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Apple Sign-In

    /// Generates the nonce and returns an ASAuthorizationAppleIDRequest
    /// configured for use with Supabase Auth.
    func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.email, .fullName]

        let nonce = generateNonce()
        currentNonce = nonce
        request.nonce = sha256(nonce)

        return request
    }

    /// Handle the authorization result from ASAuthorizationController.
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        errorMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8),
                  let nonce = currentNonce else {
                errorMessage = "Failed to get Apple ID credentials."
                return
            }

            do {
                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: nonce
                    )
                )
                currentUser = session.user
                isAuthenticated = true
                currentNonce = nil
            } catch {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }

        case .failure(let error):
            // User cancelled is not an error we need to show
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Nonce Helpers

    private func generateNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce: \(errorCode)")
                }
                return random
            }

            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
