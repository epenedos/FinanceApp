import SwiftUI

// MARK: - Settings Tab View (iPhone)

struct SettingsTabView: View {
    @Environment(\.signOutAction) private var signOutAction

    @State private var showSignOutConfirmation = false

    var body: some View {
        List {
            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Are you sure you want to sign out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task { await signOutAction?() }
            }
        }
    }
}
