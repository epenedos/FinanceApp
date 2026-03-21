import Foundation
import SwiftData
import SwiftUI

@Observable
final class AccountViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createAccount(
        name: String,
        accountType: AccountType,
        currency: SupportedCurrency,
        icon: String
    ) throws {
        let account = Account(
            name: name,
            accountType: accountType,
            currency: currency,
            icon: icon
        )
        modelContext.insert(account)
        try modelContext.save()
        SyncNotification.post(entityType: .account, entityId: account.id, changeType: .insert)
    }

    func updateAccount(
        _ account: Account,
        name: String,
        accountType: AccountType,
        currency: SupportedCurrency,
        icon: String
    ) throws {
        account.name = name
        account.accountType = accountType.rawValue
        account.currency = currency.rawValue
        account.icon = icon
        try modelContext.save()
        SyncNotification.post(entityType: .account, entityId: account.id, changeType: .update)
    }

    func deleteAccount(_ account: Account) throws {
        let accountId = account.id
        modelContext.delete(account)
        try modelContext.save()
        SyncNotification.post(entityType: .account, entityId: accountId, changeType: .delete)
    }

    func formattedBalance(for account: Account) -> String {
        CurrencyFormatter.displayString(
            cents: account.balanceInCents,
            currencyCode: account.currency
        )
    }
}
