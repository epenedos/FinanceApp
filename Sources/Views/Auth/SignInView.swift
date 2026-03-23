import SwiftUI
import AuthenticationServices

// MARK: - Sign In View

/// Full-screen sign-in view shown when the user is not authenticated.
/// Uses Sign in with Apple for a native, privacy-friendly auth flow.
struct SignInView: View {

    // MARK: - Properties

    let authManager: AuthManager

    @State private var isSigningIn = false

    // MARK: - Body

    var body: some View {
        ZStack {
            #if os(iOS)
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            #else
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            #endif

            VStack(spacing: 32) {
                Spacer()

                // App icon and title
                VStack(spacing: 16) {
                    Image(systemName: "banknote")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text(AppConstants.appName)
                        .font(.largeTitle.bold())

                    Text("Track your finances across all your devices")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Features list
                VStack(alignment: .leading, spacing: 12) {
                    featureRow(
                        icon: "building.columns",
                        title: "Multiple Accounts",
                        description: "Checking, savings, credit cards, and more"
                    )
                    featureRow(
                        icon: "arrow.left.arrow.right",
                        title: "Transfers",
                        description: "Move money between accounts"
                    )
                    featureRow(
                        icon: "chart.pie",
                        title: "Analytics",
                        description: "Spending charts and money flow diagrams"
                    )
                    featureRow(
                        icon: "icloud",
                        title: "Sync Everywhere",
                        description: "Your data on all your Apple devices"
                    )
                }
                .padding(.horizontal, 16)

                // Sign in button
                VStack(spacing: 12) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let appleRequest = authManager.createAppleIDRequest()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        },
                        onCompletion: { result in
                            isSigningIn = true
                            Task {
                                await authManager.handleAppleSignIn(result: result)
                                isSigningIn = false
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .frame(maxWidth: 320)
                    .disabled(isSigningIn)

                    if isSigningIn {
                        ProgressView()
                            .padding(.top, 8)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            #if os(iOS)
            .padding(.horizontal, 24)
            .padding(.vertical)
            #else
            .padding()
            #endif
            #if os(macOS)
            .frame(minWidth: 500, minHeight: 600)
            #endif
        }
    }

    // MARK: - Components

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
