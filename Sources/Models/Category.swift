import Foundation
import SwiftData
import SwiftUI

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "tag"
    var colorHex: String = "#007AFF"
    var transactionType: String = TransactionType.expense.rawValue
    var isDefault: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = nil

    init(
        name: String,
        icon: String,
        colorHex: String,
        transactionType: TransactionType,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.transactionType = transactionType.rawValue
        self.isDefault = isDefault
    }

    var transactionTypeEnum: TransactionType {
        TransactionType(rawValue: transactionType) ?? .expense
    }

    var color: Color {
        Color(hex: colorHex)
    }
}
