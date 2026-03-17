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
                accountHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                actionButtons
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section("Transactions") {
                if sortedTransactions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
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
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
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

    private var accountHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: account.icon)
                .font(.title.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 4) {
                Text(account.name)
                    .font(.title3.weight(.semibold))

                Text(account.accountTypeEnum.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(CurrencyFormatter.displayString(
                cents: account.balanceInCents,
                currencyCode: account.currency
            ))
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showingAddTransaction = true
            } label: {
                Label("Transaction", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                showingTransfer = true
            } label: {
                Label("Transfer", systemImage: "arrow.left.arrow.right.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.bordered)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
