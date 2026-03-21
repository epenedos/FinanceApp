import SwiftUI
import SwiftData

@main
struct FinanceApp: App {
    let modelContainer: ModelContainer

    @State private var authManager = AuthManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var syncEngine: SyncEngine?

    init() {
        do {
            let schema = Schema([
                Account.self,
                Transaction.self,
                Category.self,
                SyncMetadata.self,
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                authManager: authManager,
                networkMonitor: networkMonitor,
                onAuthenticated: { startSync() },
                onSeedCategories: {
                    DefaultCategorySeeder.seedIfNeeded(
                        modelContext: modelContainer.mainContext
                    )
                }
            )
            .environment(\.signOutAction, signOut)
        }
        .modelContainer(modelContainer)
    }

    private func signOut() async {
        syncEngine?.stop()
        syncEngine = nil
        await authManager.signOut()
    }

    private func startSync() {
        guard syncEngine == nil else { return }
        let engine = SyncEngine(
            modelContainer: modelContainer,
            authManager: authManager,
            networkMonitor: networkMonitor
        )
        syncEngine = engine
        engine.start()

        // Migrate existing local data on first sign-in
        Task {
            await engine.migrateLocalDataToSupabase()
        }
    }
}

// MARK: - Root View

/// Decides whether to show the sign-in screen or the main app content
/// based on authentication state.
private struct RootView: View {
    let authManager: AuthManager
    let networkMonitor: NetworkMonitor
    let onAuthenticated: () -> Void
    let onSeedCategories: () -> Void

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("Loading…")
            } else if authManager.isAuthenticated {
                ContentView()
                    .onAppear {
                        onSeedCategories()
                        onAuthenticated()
                    }
            } else {
                SignInView(authManager: authManager)
            }
        }
        .task {
            await authManager.restoreSession()
        }
    }
}
