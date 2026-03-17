import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var showingAddTransaction = false
    @State private var showingTransfer = false
    @State private var showingEditAccount = false

    var sortedTransactions: [Transaction] {
        (account.transactions ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: account.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.tint)

                    Text(account.name)
                        .font(.title2.bold())

                    Text(account.accountTypeEnum.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CurrencyFormatter.displayString(
                        cents: account.balanceInCents,
                        currencyCode: account.currency
                    ))
                    .font(.title.bold())
                    .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Transactions") {
                if sortedTransactions.isEmpty {
                    ContentUnavailableView {
                        Label("No Transactions", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("Add your first transaction to this account.")
                    }
                } else {
                    ForEach(sortedTransactions) { transaction in
                        TransactionRowView(
                            transaction: transaction,
                            currencyCode: account.currency
                        )
                    }
                }
            }
        }
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        Label("Add Transaction", systemImage: "plus.circle")
                    }

                    Button {
                        showingTransfer = true
                    } label: {
                        Label("Transfer", systemImage: "arrow.left.arrow.right")
                    }

                    Divider()

                    Button {
                        showingEditAccount = true
                    } label: {
                        Label("Edit Account", systemImage: "pencil")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            TransactionFormView(transaction: nil, preselectedAccount: account)
        }
        .sheet(isPresented: $showingTransfer) {
            TransferFormView(preselectedSourceAccount: account)
        }
        .sheet(isPresented: $showingEditAccount) {
            AccountFormView(account: account)
        }
    }
}
