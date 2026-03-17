import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdDate) private var accounts: [Account]
    @State private var showingAddForm = false
    @State private var accountToEdit: Account?
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: Account?

    private var totalBalance: Int64 {
        accounts.reduce(Int64(0)) { $0 + $1.balanceInCents }
    }

    var body: some View {
        Group {
            if accounts.isEmpty {
                emptyState
            } else {
                accountList
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddForm = true
                } label: {
                    Label("Add Account", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddForm) {
            AccountFormView(account: nil)
        }
        .sheet(item: $accountToEdit) { account in
            AccountFormView(account: account)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let account = accountToDelete {
                    deleteAccount(account)
                }
            }
        } message: {
            Text("This will permanently delete the account and all its transactions.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Accounts", systemImage: "building.columns")
        } description: {
            Text("Add your first account to start tracking your finances.")
        } actions: {
            Button("Add Account") {
                showingAddForm = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var accountList: some View {
        List {
            Section {
                totalBalanceHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(accounts) { account in
                    NavigationLink {
                        AccountDetailView(account: account)
                    } label: {
                        AccountRowView(account: account)
                    }
                    .contextMenu {
                        Button {
                            accountToEdit = account
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            accountToDelete = account
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            accountToDelete = account
                            showingDeleteAlert = true
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
    }

    private var totalBalanceHeader: some View {
        VStack(spacing: 4) {
            Text("Total Balance")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(CurrencyFormatter.displayString(
                cents: totalBalance,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundColor(totalBalance >= 0 ? .primary : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func deleteAccount(_ account: Account) {
        do {
            let viewModel = AccountViewModel(modelContext: modelContext)
            try viewModel.deleteAccount(account)
        } catch {
            print("Failed to delete account: \(error)")
        }
    }
}

struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: account.icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.body.weight(.medium))
                Text(account.accountTypeEnum.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(CurrencyFormatter.displayString(
                cents: account.balanceInCents,
                currencyCode: account.currency
            ))
            .font(.system(.body, design: .rounded, weight: .semibold))
            .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 6)
    }
}
