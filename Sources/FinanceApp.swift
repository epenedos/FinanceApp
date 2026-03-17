import SwiftUI
import SwiftData
import CoreData

@main
struct FinanceApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Account.self,
                Transaction.self,
                Category.self,
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Enable persistent history tracking for remote change detection
            setupRemoteChangeNotifications()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DefaultCategorySeeder.seedIfNeeded(
                        modelContext: modelContainer.mainContext
                    )
                }
        }
        .modelContainer(modelContainer)
    }

    private func setupRemoteChangeNotifications() {
        // NSPersistentStoreRemoteChange fires when CloudKit merges
        // remote data into the local persistent store
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            // Merge remote changes into the main context so @Query updates
            Task { @MainActor in
                modelContainer.mainContext.processPendingChanges()
            }
        }

        // Also listen for CloudKit container events for error logging
        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else {
                return
            }

            if let error = event.error {
                print("CloudKit sync error: \(error.localizedDescription)")
            }
        }
    }
}
