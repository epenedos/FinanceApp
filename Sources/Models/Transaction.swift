import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var amountInCents: Int64 = 0
    var transactionType: String = TransactionType.expense.rawValue
    var date: Date = Date.now
    var notes: String = ""
    var transferId: String? = nil

    var account: Account? = nil
    var category: Category? = nil

    init(
        amountInCents: Int64,
        transactionType: TransactionType,
        date: Date,
        notes: String,
        transferId: String? = nil,
        account: Account?,
        category: Category?
    ) {
        self.id = UUID()
        self.amountInCents = amountInCents
        self.transactionType = transactionType.rawValue
        self.date = date
        self.notes = notes
        self.transferId = transferId
        self.account = account
        self.category = category
    }

    var transactionTypeEnum: TransactionType {
        TransactionType(rawValue: transactionType) ?? .expense
    }

    var isTransfer: Bool {
        transferId != nil
    }
}
