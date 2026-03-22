import Foundation

enum AppConstants {
    static let appName = "FinanceApp"
    static let defaultCurrencyCode = "USD"
    static let recentTransactionsLimit = 10
    static let migrationCompletedKey = "supabaseMigrationCompleted"
    static let lastSyncTimestampKey = "lastSyncTimestamp"

    // MARK: - Supabase

    static let supabaseURL = URL(string: "https://teeloaxiplwfvonsnudw.supabase.co")!
    static let supabaseAnonKey = "sb_publishable_vSfgpXsaNd4vpolW8NNCDA_ck9Z-PLx"
}
