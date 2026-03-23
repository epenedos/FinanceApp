import Foundation
import SwiftData

// MARK: - Supabase Row DTOs (Codable)

/// Data transfer objects matching the PostgreSQL schema.
/// Used for serializing to/from Supabase PostgREST.

struct SupabaseAccountRow: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let accountType: String
    let currency: String
    let icon: String
    let createdDate: String
    let updatedAt: String
    let deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case accountType = "account_type"
        case currency
        case icon
        case createdDate = "created_date"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct SupabaseTransactionRow: Codable, Sendable {
    let id: String
    let userId: String
    let amountInCents: Int64
    let transactionType: String
    let date: String
    let notes: String
    let transferId: String?
    let accountId: String?
    let categoryId: String?
    let updatedAt: String
    let deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case amountInCents = "amount_in_cents"
        case transactionType = "transaction_type"
        case date
        case notes
        case transferId = "transfer_id"
        case accountId = "account_id"
        case categoryId = "category_id"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

struct SupabaseCategoryRow: Codable, Sendable {
    let id: String
    let userId: String
    let name: String
    let icon: String
    let colorHex: String
    let transactionType: String
    let isDefault: Bool
    let updatedAt: String
    let deletedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case icon
        case colorHex = "color_hex"
        case transactionType = "transaction_type"
        case isDefault = "is_default"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
}

// MARK: - Soft Delete DTO

struct SoftDeleteRow: Codable, Sendable {
    let deletedAt: String

    enum CodingKeys: String, CodingKey {
        case deletedAt = "deleted_at"
    }
}

// MARK: - Entity Mapper

/// Bidirectional mapping between SwiftData @Model objects and
/// Supabase Codable row DTOs.
enum EntityMapper {

    // MARK: - Date Formatting

    private static func nowISO() -> String {
        ISO8601DateFormatter().string(from: Date.now)
    }

    static func parseDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private static func formatDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    // MARK: - Account

    static func toRow(account: Account, userId: UUID) -> SupabaseAccountRow {
        SupabaseAccountRow(
            id: account.id.uuidString,
            userId: userId.uuidString,
            name: account.name,
            accountType: account.accountType,
            currency: account.currency,
            icon: account.icon,
            createdDate: formatDate(account.createdDate),
            updatedAt: nowISO(),
            deletedAt: nil
        )
    }

    static func updateAccount(_ account: Account, from row: SupabaseAccountRow) {
        account.name = row.name
        account.accountType = row.accountType
        account.currency = row.currency
        account.icon = row.icon
        if let date = parseDate(row.createdDate) {
            account.createdDate = date
        }
    }

    static func createAccount(from row: SupabaseAccountRow) -> Account? {
        guard UUID(uuidString: row.id) != nil else { return nil }
        let accountType = AccountType(rawValue: row.accountType) ?? .checking
        let currency = SupportedCurrency(rawValue: row.currency) ?? .usd
        let account = Account(
            name: row.name,
            accountType: accountType,
            currency: currency,
            icon: row.icon
        )
        // Override the auto-generated id with the remote one
        if let id = UUID(uuidString: row.id) {
            account.id = id
        }
        if let date = parseDate(row.createdDate) {
            account.createdDate = date
        }
        return account
    }

    // MARK: - Transaction

    static func toRow(transaction: Transaction, userId: UUID) -> SupabaseTransactionRow {
        SupabaseTransactionRow(
            id: transaction.id.uuidString,
            userId: userId.uuidString,
            amountInCents: transaction.amountInCents,
            transactionType: transaction.transactionType,
            date: formatDate(transaction.date),
            notes: transaction.notes,
            transferId: transaction.transferId,
            accountId: transaction.account?.id.uuidString,
            categoryId: transaction.category?.id.uuidString,
            updatedAt: nowISO(),
            deletedAt: nil
        )
    }

    static func updateTransaction(
        _ transaction: Transaction,
        from row: SupabaseTransactionRow
    ) {
        transaction.amountInCents = row.amountInCents
        transaction.transactionType = row.transactionType
        if let date = parseDate(row.date) {
            transaction.date = date
        }
        transaction.notes = row.notes
        transaction.transferId = row.transferId
    }

    static func createTransaction(from row: SupabaseTransactionRow) -> Transaction? {
        guard UUID(uuidString: row.id) != nil else { return nil }
        let type = TransactionType(rawValue: row.transactionType) ?? .expense
        let date = parseDate(row.date) ?? Date.now
        let transaction = Transaction(
            amountInCents: row.amountInCents,
            transactionType: type,
            date: date,
            notes: row.notes,
            transferId: row.transferId,
            account: nil,
            category: nil
        )
        if let id = UUID(uuidString: row.id) {
            transaction.id = id
        }
        return transaction
    }

    // MARK: - Category

    static func toRow(category: Category, userId: UUID) -> SupabaseCategoryRow {
        SupabaseCategoryRow(
            id: category.id.uuidString,
            userId: userId.uuidString,
            name: category.name,
            icon: category.icon,
            colorHex: category.colorHex,
            transactionType: category.transactionType,
            isDefault: category.isDefault,
            updatedAt: nowISO(),
            deletedAt: nil
        )
    }

    static func updateCategory(_ category: Category, from row: SupabaseCategoryRow) {
        category.name = row.name
        category.icon = row.icon
        category.colorHex = row.colorHex
        category.transactionType = row.transactionType
        category.isDefault = row.isDefault
    }

    static func createCategory(from row: SupabaseCategoryRow) -> Category? {
        guard UUID(uuidString: row.id) != nil else { return nil }
        let type = TransactionType(rawValue: row.transactionType) ?? .expense
        let category = Category(
            name: row.name,
            icon: row.icon,
            colorHex: row.colorHex,
            transactionType: type,
            isDefault: row.isDefault
        )
        if let id = UUID(uuidString: row.id) {
            category.id = id
        }
        return category
    }
}
