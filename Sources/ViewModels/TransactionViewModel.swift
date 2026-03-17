import Foundation
import SwiftData
import SwiftUI

@Observable
final class TransactionViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createTransaction(
        amountInCents: Int64,
        transactionType: TransactionType,
        date: Date,
        notes: String,
        account: Account,
        category: Category
    ) throws {
        let transaction = Transaction(
            amountInCents: amountInCents,
            transactionType: transactionType,
            date: date,
            notes: notes,
            account: account,
            category: category
        )
        modelContext.insert(transaction)
        try modelContext.save()
    }

    func updateTransaction(
        _ transaction: Transaction,
        amountInCents: Int64,
        transactionType: TransactionType,
        date: Date,
        notes: String,
        account: Account,
        category: Category
    ) throws {
        transaction.amountInCents = amountInCents
        transaction.transactionType = transactionType.rawValue
        transaction.date = date
        transaction.notes = notes
        transaction.account = account
        transaction.category = category
        try modelContext.save()
    }

    func deleteTransaction(_ transaction: Transaction) throws {
        if let transferId = transaction.transferId {
            try deleteTransferPair(transferId: transferId)
        } else {
            modelContext.delete(transaction)
            try modelContext.save()
        }
    }

    private func deleteTransferPair(transferId: String) throws {
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.transferId == transferId }
        )
        let paired = try modelContext.fetch(descriptor)
        for transaction in paired {
            modelContext.delete(transaction)
        }
        try modelContext.save()
    }
}
