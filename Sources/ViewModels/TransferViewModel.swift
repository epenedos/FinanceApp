import Foundation
import SwiftData

@Observable
final class TransferViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func executeTransfer(
        from sourceAccount: Account,
        to destinationAccount: Account,
        amountInCents: Int64,
        date: Date,
        notes: String
    ) throws {
        let transferId = UUID().uuidString

        var newCategoryChanges: [SyncNotification.Change] = []
        let transferCategory = try findOrCreateTransferCategory(
            type: .expense, newChanges: &newCategoryChanges
        )
        let transferIncomeCategory = try findOrCreateTransferCategory(
            type: .income, newChanges: &newCategoryChanges
        )

        let defaultNotes = notes.isEmpty
            ? "Transfer from \(sourceAccount.name) to \(destinationAccount.name)"
            : notes

        let debit = Transaction(
            amountInCents: amountInCents,
            transactionType: .expense,
            date: date,
            notes: defaultNotes,
            transferId: transferId,
            account: sourceAccount,
            category: transferCategory
        )

        let credit = Transaction(
            amountInCents: amountInCents,
            transactionType: .income,
            date: date,
            notes: defaultNotes,
            transferId: transferId,
            account: destinationAccount,
            category: transferIncomeCategory
        )

        modelContext.insert(debit)
        modelContext.insert(credit)
        try modelContext.save()

        SyncNotification.post(changes: newCategoryChanges + [
            .init(entityType: .transaction, entityId: debit.id, changeType: .insert),
            .init(entityType: .transaction, entityId: credit.id, changeType: .insert),
        ])
    }

    private func findOrCreateTransferCategory(
        type: TransactionType,
        newChanges: inout [SyncNotification.Change]
    ) throws -> Category {
        let typeRaw = type.rawValue
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate<Category> {
                $0.name == "Transfer" && $0.transactionType == typeRaw
            }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let category = Category(
            name: "Transfer",
            icon: "arrow.left.arrow.right",
            colorHex: "#607D8B",
            transactionType: type,
            isDefault: true
        )
        modelContext.insert(category)
        newChanges.append(.init(entityType: .category, entityId: category.id, changeType: .insert))
        return category
    }
}
