import Foundation
import Supabase

// MARK: - Supabase Client Singleton

/// Provides a single shared Supabase client instance configured from AppConstants.
/// All Supabase interactions (auth, database, realtime) go through this client.
enum SupabaseManager {

    static let client = SupabaseClient(
        supabaseURL: AppConstants.supabaseURL,
        supabaseKey: AppConstants.supabaseAnonKey
    )
}
