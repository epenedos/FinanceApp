import Foundation

// MARK: - Sync Change Notification

/// Lightweight notification system for SwiftData saves.
///
/// SwiftData's `ModelContext.save()` does NOT post
/// `NSManagedObjectContextDidSave` (that's Core Data only).
/// ViewModels post `.didSaveLocalData` after each save so
/// SyncEngine can queue the change for push.
enum SyncNotification {

    /// Posted by ViewModels after a successful `modelContext.save()`.
    static let didSaveLocalData = Notification.Name("SyncDidSaveLocalData")

    // MARK: - UserInfo Keys

    static let changesKey = "syncChanges"

    // MARK: - Change Descriptor

    /// Describes a single entity change to be synced.
    struct Change: Sendable {
        let entityType: SyncMetadata.EntityType
        let entityId: UUID
        let changeType: SyncMetadata.ChangeType
    }

    // MARK: - Post Helpers

    /// Post a single entity change.
    static func post(
        entityType: SyncMetadata.EntityType,
        entityId: UUID,
        changeType: SyncMetadata.ChangeType
    ) {
        let change = Change(
            entityType: entityType,
            entityId: entityId,
            changeType: changeType
        )
        NotificationCenter.default.post(
            name: didSaveLocalData,
            object: nil,
            userInfo: [changesKey: [change]]
        )
    }

    /// Post multiple entity changes at once (e.g., transfer pairs).
    static func post(changes: [Change]) {
        guard !changes.isEmpty else { return }
        NotificationCenter.default.post(
            name: didSaveLocalData,
            object: nil,
            userInfo: [changesKey: changes]
        )
    }
}
