import Foundation
import SwiftData

struct DefaultCategorySeeder {
    private init() {}

    static func seedIfNeeded(modelContext: ModelContext) {
        // Check the database for existing categories instead of a device-local flag.
        // This prevents duplicate seeding across devices — if categories were already
        // pulled from Supabase sync, we skip seeding entirely.
        let descriptor = FetchDescriptor<Category>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let expenseCategories: [(String, String, String)] = [
            ("Food & Dining", "fork.knife", "#FF6B6B"),
            ("Groceries", "cart", "#FF8E53"),
            ("Transportation", "car", "#FFC107"),
            ("Housing", "house", "#4CAF50"),
            ("Utilities", "bolt", "#2196F3"),
            ("Healthcare", "heart", "#E91E63"),
            ("Entertainment", "film", "#9C27B0"),
            ("Shopping", "bag", "#673AB7"),
            ("Education", "book", "#3F51B5"),
            ("Personal Care", "person", "#00BCD4"),
            ("Travel", "airplane", "#009688"),
            ("Gifts", "gift", "#795548"),
            ("Insurance", "shield", "#607D8B"),
            ("Subscriptions", "repeat", "#FF5722"),
            ("Other", "ellipsis.circle", "#9E9E9E"),
        ]

        let incomeCategories: [(String, String, String)] = [
            ("Salary", "briefcase", "#4CAF50"),
            ("Freelance", "laptopcomputer", "#8BC34A"),
            ("Investment", "chart.line.uptrend.xyaxis", "#CDDC39"),
            ("Rental", "house", "#FFEB3B"),
            ("Gift", "gift", "#FFC107"),
            ("Refund", "arrow.uturn.backward", "#FF9800"),
            ("Other", "ellipsis.circle", "#9E9E9E"),
        ]

        for (name, icon, color) in expenseCategories {
            let category = Category(
                name: name,
                icon: icon,
                colorHex: color,
                transactionType: .expense,
                isDefault: true
            )
            modelContext.insert(category)
        }

        for (name, icon, color) in incomeCategories {
            let category = Category(
                name: name,
                icon: icon,
                colorHex: color,
                transactionType: .income,
                isDefault: true
            )
            modelContext.insert(category)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to seed default categories: \(error)")
        }
    }
}
