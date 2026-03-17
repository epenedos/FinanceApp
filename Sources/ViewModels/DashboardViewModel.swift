import Foundation
import SwiftData

@Observable
final class DashboardViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func totalBalance(accounts: [Account]) -> Int64 {
        accounts.reduce(Int64(0)) { $0 + $1.balanceInCents }
    }

    func monthlyIncome(transactions: [Transaction], month: Date) -> Int64 {
        let start = month.startOfMonth
        let end = month.endOfMonth
        let incomeType = TransactionType.income.rawValue

        return transactions
            .filter { $0.date >= start && $0.date <= end && $0.transactionType == incomeType }
            .reduce(Int64(0)) { $0 + $1.amountInCents }
    }

    func monthlyExpenses(transactions: [Transaction], month: Date) -> Int64 {
        let start = month.startOfMonth
        let end = month.endOfMonth
        let expenseType = TransactionType.expense.rawValue

        return transactions
            .filter { $0.date >= start && $0.date <= end && $0.transactionType == expenseType }
            .reduce(Int64(0)) { $0 + $1.amountInCents }
    }

    func spendingByCategory(
        transactions: [Transaction],
        from: Date,
        to: Date
    ) -> [(category: Category, totalCents: Int64)] {
        let expenseType = TransactionType.expense.rawValue
        let filtered = transactions.filter {
            $0.date >= from && $0.date <= to && $0.transactionType == expenseType
        }

        var grouped: [UUID: (category: Category, total: Int64)] = [:]
        for transaction in filtered {
            guard let category = transaction.category else { continue }
            let key = category.id
            if let existing = grouped[key] {
                grouped[key] = (category: existing.category, total: existing.total + transaction.amountInCents)
            } else {
                grouped[key] = (category: category, total: transaction.amountInCents)
            }
        }

        return grouped.values
            .map { (category: $0.category, totalCents: $0.total) }
            .sorted { $0.totalCents > $1.totalCents }
    }

    func recentTransactions(transactions: [Transaction], limit: Int = AppConstants.recentTransactionsLimit) -> [Transaction] {
        transactions
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
}
