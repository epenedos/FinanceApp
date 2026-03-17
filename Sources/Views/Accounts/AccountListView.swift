import SwiftUI
import SwiftData

struct AccountListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdDate) private var accounts: [Account]
    @State private var showingAddForm = false
    @State private var accountToEdit: Account?
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: Account?

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
            ForEach(accounts) { account in
                NavigationLink {
                    AccountDetailView(account: account)
                } label: {
                    AccountRowView(account: account)
                }
                .contextMenu {
                    Button("Edit") {
                        accountToEdit = account
                    }
                    Button("Delete", role: .destructive) {
                        accountToDelete = account
                        showingDeleteAlert = true
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
        HStack {
            Image(systemName: account.icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                Text(account.accountTypeEnum.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(CurrencyFormatter.displayString(
                cents: account.balanceInCents,
                currencyCode: account.currency
            ))
            .font(.headline)
            .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
        }
        .padding(.vertical, 4)
    }
}
