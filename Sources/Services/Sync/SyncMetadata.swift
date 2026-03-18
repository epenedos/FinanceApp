import Foundation
import SwiftData

// MARK: - Sync Change Tracking (Outbox Pattern)

/// Tracks local changes that need to be pushed to Supabase.
/// Each record represents a pending insert, update, or delete
/// that has not yet been confirmed by the remote server.
@Model
final class SyncMetadata {

    // MARK: - Properties

    var id: UUID = UUID()
    var entityType: String = ""
    var entityId: String = ""
    var changeType: String = ChangeType.insert.rawValue
    var timestamp: Date = Date.now
    var isSynced: Bool = false
    var retryCount: Int = 0

    // MARK: - Types

    enum ChangeType: String, Codable {
        case insert
        case update
        case delete
    }

    enum EntityType: String, Codable {
        case account
        case transaction
        case category
    }

    // MARK: - Computed

    var changeTypeEnum: ChangeType {
        ChangeType(rawValue: changeType) ?? .insert
    }

    var entityTypeEnum: EntityType {
        EntityType(rawValue: entityType) ?? .account
    }

    // MARK: - Init

    init(
        entityType: EntityType,
        entityId: UUID,
        changeType: ChangeType
    ) {
        self.id = UUID()
        self.entityType = entityType.rawValue
        self.entityId = entityId.uuidString
        self.changeType = changeType.rawValue
        self.timestamp = Date.now
        self.isSynced = false
        self.retryCount = 0
    }
}
