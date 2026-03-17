import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var accountType: String = AccountType.checking.rawValue
    var currency: String = SupportedCurrency.usd.rawValue
    var icon: String = "building.columns"
    var createdDate: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]? = nil

    init(
        name: String,
        accountType: AccountType,
        currency: SupportedCurrency,
        icon: String
    ) {
        self.id = UUID()
        self.name = name
        self.accountType = accountType.rawValue
        self.currency = currency.rawValue
        self.icon = icon
        self.createdDate = Date.now
    }

    var accountTypeEnum: AccountType {
        AccountType(rawValue: accountType) ?? .checking
    }

    var currencyEnum: SupportedCurrency {
        SupportedCurrency(rawValue: currency) ?? .usd
    }

    var balanceInCents: Int64 {
        guard let transactions else { return 0 }
        return transactions.reduce(Int64(0)) { sum, transaction in
            let amount = transaction.amountInCents
            if transaction.transactionType == TransactionType.income.rawValue {
                return sum + amount
            } else {
                return sum - amount
            }
        }
    }
}
