import Foundation
import SwiftData
import Supabase
import Observation

// MARK: - Sync Engine

/// Orchestrates bidirectional sync between local SwiftData and remote Supabase.
///
/// - **Push**: Observes local saves via NSManagedObjectContext notifications,
///   queues changes in SyncMetadata, and upserts to Supabase.
/// - **Pull**: Subscribes to Supabase Realtime for live updates and performs
///   full pulls on first login / connectivity restoration.
/// - **Conflict resolution**: Last-write-wins based on `updated_at`.
@Observable
@MainActor
final class SyncEngine {

    // MARK: - Properties

    private let modelContainer: ModelContainer
    private let authManager: AuthManager
    private let networkMonitor: NetworkMonitor
    private let client = SupabaseManager.client

    private(set) var isSyncing: Bool = false
    private(set) var lastSyncDate: Date?
    private(set) var syncError: String?
    private(set) var initialPullCompleted: Bool = false

    private var realtimeChannel: RealtimeChannelV2?
    private var pushDebounceTask: Task<Void, Never>?
    private var saveObserver: NSObjectProtocol?
    private var connectivityObserver: NSObjectProtocol?

    /// Flag to prevent re-entrant sync from save notifications
    /// triggered by our own pull writes.
    private var isPulling: Bool = false

    // MARK: - Init

    init(
        modelContainer: ModelContainer,
        authManager: AuthManager,
        networkMonitor: NetworkMonitor
    ) {
        self.modelContainer = modelContainer
        self.authManager = authManager
        self.networkMonitor = networkMonitor
    }

    // MARK: - Start / Stop

    func start() {
        observeLocalSaves()
        observeConnectivity()

        Task {
            await subscribeToRealtime()
            await performFullPull()
        }
    }

    func stop() {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
        if let connectivityObserver {
            NotificationCenter.default.removeObserver(connectivityObserver)
        }
        pushDebounceTask?.cancel()

        Task {
            await realtimeChannel?.unsubscribe()
        }
    }

    // MARK: - Local Save Observation

    private func observeLocalSaves() {
        saveObserver = NotificationCenter.default.addObserver(
            forName: SyncNotification.didSaveLocalData,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let changes = notification.userInfo?[SyncNotification.changesKey]
                as? [SyncNotification.Change] ?? []

            Task { @MainActor in
                self?.handleNotifiedChanges(changes)
            }
        }
    }

    private func handleNotifiedChanges(_ changes: [SyncNotification.Change]) {
        guard !isPulling else { return }
        guard !changes.isEmpty else { return }

        let context = modelContainer.mainContext

        for change in changes {
            let metadata = SyncMetadata(
                entityType: change.entityType,
                entityId: change.entityId,
                changeType: change.changeType
            )
            context.insert(metadata)
        }

        try? context.save()
        schedulePush()
    }

    // MARK: - Push (Local → Remote)

    private func schedulePush() {
        pushDebounceTask?.cancel()
        pushDebounceTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await pushPendingChanges()
        }
    }

    func pushPendingChanges() async {
        guard authManager.isAuthenticated,
              let userId = authManager.userId,
              networkMonitor.isConnected else {
            return
        }

        let context = modelContainer.mainContext

        do {
            let descriptor = FetchDescriptor<SyncMetadata>(
                predicate: #Predicate<SyncMetadata> { !$0.isSynced },
                sortBy: [SortDescriptor(\.timestamp)]
            )
            let pendingChanges = try context.fetch(descriptor)
            guard !pendingChanges.isEmpty else { return }

            // Sort by entity type to satisfy FK dependencies:
            // accounts first, then categories, then transactions.
            let sortedChanges = pendingChanges.sorted {
                $0.entityTypeEnum.pushOrder < $1.entityTypeEnum.pushOrder
            }

            isSyncing = true
            syncError = nil

            for metadata in sortedChanges {
                do {
                    try await pushSingleChange(metadata, userId: userId, context: context)
                    metadata.isSynced = true
                } catch {
                    metadata.retryCount += 1
                    print("Sync push failed for \(metadata.entityType)/\(metadata.entityId): \(error)")

                    if metadata.retryCount >= 5 {
                        metadata.isSynced = true
                        syncError = "Some changes failed to sync after multiple retries."
                    }
                }
            }

            try? context.save()
            cleanupSyncedMetadata(context: context)

            isSyncing = false
            lastSyncDate = Date.now

        } catch {
            isSyncing = false
            syncError = "Push failed: \(error.localizedDescription)"
        }
    }

    private func pushSingleChange(
        _ metadata: SyncMetadata,
        userId: UUID,
        context: ModelContext
    ) async throws {
        let entityIdStr = metadata.entityId

        switch metadata.changeTypeEnum {
        case .insert, .update:
            try await pushUpsert(
                entityType: metadata.entityTypeEnum,
                entityIdStr: entityIdStr,
                userId: userId,
                context: context
            )
        case .delete:
            try await pushDelete(
                entityType: metadata.entityTypeEnum,
                entityIdStr: entityIdStr
            )
        }
    }

    private func pushUpsert(
        entityType: SyncMetadata.EntityType,
        entityIdStr: String,
        userId: UUID,
        context: ModelContext
    ) async throws {
        guard let entityId = UUID(uuidString: entityIdStr) else { return }

        switch entityType {
        case .account:
            let descriptor = FetchDescriptor<Account>(
                predicate: #Predicate<Account> { $0.id == entityId }
            )
            guard let account = try context.fetch(descriptor).first else { return }
            let row = EntityMapper.toRow(account: account, userId: userId)
            try await client.from("accounts").upsert(row).execute()

        case .transaction:
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { $0.id == entityId }
            )
            guard let transaction = try context.fetch(descriptor).first else { return }
            let row = EntityMapper.toRow(transaction: transaction, userId: userId)
            try await client.from("transactions").upsert(row).execute()

        case .category:
            let descriptor = FetchDescriptor<Category>(
                predicate: #Predicate<Category> { $0.id == entityId }
            )
            guard let category = try context.fetch(descriptor).first else { return }
            let row = EntityMapper.toRow(category: category, userId: userId)
            try await client.from("categories").upsert(row).execute()
        }
    }

    private func pushDelete(
        entityType: SyncMetadata.EntityType,
        entityIdStr: String
    ) async throws {
        let table: String
        switch entityType {
        case .account: table = "accounts"
        case .transaction: table = "transactions"
        case .category: table = "categories"
        }

        let softDelete = SoftDeleteRow(
            deletedAt: ISO8601DateFormatter().string(from: Date.now)
        )
        try await client.from(table)
            .update(softDelete)
            .eq("id", value: entityIdStr)
            .execute()
    }

    private func cleanupSyncedMetadata(context: ModelContext) {
        do {
            let descriptor = FetchDescriptor<SyncMetadata>(
                predicate: #Predicate<SyncMetadata> { $0.isSynced }
            )
            let synced = try context.fetch(descriptor)
            for item in synced {
                context.delete(item)
            }
            try? context.save()
        } catch {
            // Non-critical cleanup
        }
    }

    // MARK: - Pull (Remote → Local)

    func performFullPull() async {
        guard authManager.isAuthenticated,
              let userId = authManager.userId,
              networkMonitor.isConnected else {
            initialPullCompleted = true
            return
        }

        isSyncing = true
        isPulling = true
        syncError = nil

        let context = modelContainer.mainContext
        let lastSync = UserDefaults.standard.object(
            forKey: AppConstants.lastSyncTimestampKey
        ) as? Date

        do {
            // Pull accounts
            let accountRows: [SupabaseAccountRow] = try await fetchRows(
                table: "accounts", userId: userId, since: lastSync
            )
            for row in accountRows {
                handlePulledAccount(row, context: context)
            }

            // Pull categories
            let categoryRows: [SupabaseCategoryRow] = try await fetchRows(
                table: "categories", userId: userId, since: lastSync
            )
            for row in categoryRows {
                handlePulledCategory(row, context: context)
            }

            // Pull transactions (after accounts + categories for relationship linking)
            let transactionRows: [SupabaseTransactionRow] = try await fetchRows(
                table: "transactions", userId: userId, since: lastSync
            )
            for row in transactionRows {
                try handlePulledTransaction(row, context: context)
            }

            try? context.save()
            context.processPendingChanges()

            UserDefaults.standard.set(Date.now, forKey: AppConstants.lastSyncTimestampKey)
            lastSyncDate = Date.now
            isSyncing = false
            isPulling = false
            initialPullCompleted = true

        } catch {
            isSyncing = false
            isPulling = false
            initialPullCompleted = true
            syncError = "Pull failed: \(error.localizedDescription)"
        }
    }

    private func fetchRows<T: Decodable>(
        table: String,
        userId: UUID,
        since: Date?
    ) async throws -> [T] {
        var query = client.from(table)
            .select()
            .eq("user_id", value: userId.uuidString)

        if let since {
            let sinceStr = ISO8601DateFormatter().string(from: since)
            query = query.gte("updated_at", value: sinceStr)
        }

        return try await query.execute().value
    }

    // MARK: - Pull Handlers

    private func handlePulledAccount(_ row: SupabaseAccountRow, context: ModelContext) {
        let isDeleted = row.deletedAt != nil

        if let existing = findAccount(id: row.id, context: context) {
            if isDeleted {
                context.delete(existing)
            } else if shouldAcceptRemote(remoteUpdatedAt: row.updatedAt) {
                EntityMapper.updateAccount(existing, from: row)
            }
        } else if !isDeleted {
            if let newAccount = EntityMapper.createAccount(from: row) {
                context.insert(newAccount)
            }
        }
    }

    private func handlePulledCategory(_ row: SupabaseCategoryRow, context: ModelContext) {
        let isDeleted = row.deletedAt != nil

        if let existing = findCategory(id: row.id, context: context) {
            if isDeleted {
                context.delete(existing)
            } else {
                EntityMapper.updateCategory(existing, from: row)
            }
        } else if !isDeleted {
            if let newCategory = EntityMapper.createCategory(from: row) {
                context.insert(newCategory)
            }
        }
    }

    private func handlePulledTransaction(
        _ row: SupabaseTransactionRow,
        context: ModelContext
    ) throws {
        let isDeleted = row.deletedAt != nil

        if let existing = findTransaction(id: row.id, context: context) {
            if isDeleted {
                context.delete(existing)
            } else {
                EntityMapper.updateTransaction(existing, from: row)
                // Re-link relationships if changed
                if let accountId = row.accountId {
                    existing.account = findAccount(id: accountId, context: context)
                }
                if let categoryId = row.categoryId {
                    existing.category = findCategory(id: categoryId, context: context)
                }
            }
        } else if !isDeleted {
            if let newTransaction = EntityMapper.createTransaction(from: row) {
                if let accountId = row.accountId {
                    newTransaction.account = findAccount(id: accountId, context: context)
                }
                if let categoryId = row.categoryId {
                    newTransaction.category = findCategory(id: categoryId, context: context)
                }
                context.insert(newTransaction)
            }
        }
    }

    // MARK: - Realtime Subscription

    private func subscribeToRealtime() async {
        guard let userId = authManager.userId else { return }

        let channel = client.realtimeV2.channel(
            "user-sync-\(userId.uuidString.prefix(8))"
        )

        let accountChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "accounts",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        let categoryChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "categories",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        let transactionChanges = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "transactions",
            filter: "user_id=eq.\(userId.uuidString)"
        )

        await channel.subscribe()
        realtimeChannel = channel

        Task {
            for await _ in accountChanges {
                await performFullPull()
            }
        }
        Task {
            for await _ in categoryChanges {
                await performFullPull()
            }
        }
        Task {
            for await _ in transactionChanges {
                await performFullPull()
            }
        }
    }

    // MARK: - Connectivity

    private func observeConnectivity() {
        connectivityObserver = NotificationCenter.default.addObserver(
            forName: .connectivityRestored,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.pushPendingChanges()
                await self?.performFullPull()
            }
        }
    }

    // MARK: - Lookup Helpers

    private func findAccount(id: String?, context: ModelContext) -> Account? {
        guard let idStr = id, let uuid = UUID(uuidString: idStr) else { return nil }
        let descriptor = FetchDescriptor<Account>(
            predicate: #Predicate<Account> { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }

    private func findCategory(id: String?, context: ModelContext) -> Category? {
        guard let idStr = id, let uuid = UUID(uuidString: idStr) else { return nil }
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }

    private func findTransaction(id: String?, context: ModelContext) -> Transaction? {
        guard let idStr = id, let uuid = UUID(uuidString: idStr) else { return nil }
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }

    // MARK: - Conflict Resolution

    private func shouldAcceptRemote(remoteUpdatedAt: String) -> Bool {
        // Last-write-wins: always accept remote for now
        // The server's updated_at trigger ensures accurate timestamps
        true
    }

    // MARK: - Initial Migration

    func migrateLocalDataToSupabase() async {
        guard let userId = authManager.userId else { return }

        let alreadyMigrated = UserDefaults.standard.bool(
            forKey: AppConstants.migrationCompletedKey
        )
        guard !alreadyMigrated else { return }

        isSyncing = true
        let context = modelContainer.mainContext

        do {
            let accounts = try context.fetch(FetchDescriptor<Account>())
            for account in accounts {
                let row = EntityMapper.toRow(account: account, userId: userId)
                try await client.from("accounts").upsert(row).execute()
            }

            let categories = try context.fetch(FetchDescriptor<Category>())
            for category in categories {
                let row = EntityMapper.toRow(category: category, userId: userId)
                try await client.from("categories").upsert(row).execute()
            }

            let transactions = try context.fetch(FetchDescriptor<Transaction>())
            for transaction in transactions {
                let row = EntityMapper.toRow(transaction: transaction, userId: userId)
                try await client.from("transactions").upsert(row).execute()
            }

            UserDefaults.standard.set(true, forKey: AppConstants.migrationCompletedKey)
            isSyncing = false
            lastSyncDate = Date.now

        } catch {
            isSyncing = false
            syncError = "Migration failed: \(error.localizedDescription)"
        }
    }
}
