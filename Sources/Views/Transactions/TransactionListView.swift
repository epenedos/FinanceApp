import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var showingAddTransaction = false
    @State private var searchText = ""
    @State private var filterType: TransactionType?
    @State private var filterAccount: Account?
    @State private var showingDeleteAlert = false
    @State private var transactionToDelete: Transaction?

    private var filteredTransactions: [Transaction] {
        var results = allTransactions

        if let filterType {
            results = results.filter { $0.transactionType == filterType.rawValue }
        }

        if let filterAccount {
            results = results.filter { $0.account?.id == filterAccount.id }
        }

        if !searchText.isEmpty {
            let search = searchText.lowercased()
            results = results.filter {
                $0.notes.lowercased().contains(search) ||
                ($0.category?.name.lowercased().contains(search) ?? false)
            }
        }

        return results
    }

    var body: some View {
        Group {
            if allTransactions.isEmpty {
                emptyState
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Label("Add Transaction", systemImage: "plus")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search transactions")
        .sheet(isPresented: $showingAddTransaction) {
            TransactionFormView(transaction: nil)
        }
        .alert("Delete Transaction", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let transaction = transactionToDelete {
                    deleteTransaction(transaction)
                }
            }
        } message: {
            if transactionToDelete?.isTransfer == true {
                Text("This will delete both sides of the transfer.")
            } else {
                Text("This transaction will be permanently deleted.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Transactions", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Add your first transaction to start tracking.")
        } actions: {
            Button("Add Transaction") {
                showingAddTransaction = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var transactionList: some View {
        List {
            Section {
                filterBar
            }

            ForEach(filteredTransactions) { transaction in
                TransactionRowView(
                    transaction: transaction,
                    currencyCode: transaction.account?.currency ?? AppConstants.defaultCurrencyCode
                )
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        transactionToDelete = transaction
                        showingDeleteAlert = true
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: "All",
                    isSelected: filterType == nil,
                    action: { filterType = nil }
                )
                FilterChip(
                    title: "Income",
                    isSelected: filterType == .income,
                    action: { filterType = .income }
                )
                FilterChip(
                    title: "Expense",
                    isSelected: filterType == .expense,
                    action: { filterType = .expense }
                )

                Divider().frame(height: 20)

                Menu {
                    Button("All Accounts") { filterAccount = nil }
                    ForEach(accounts) { account in
                        Button(account.name) { filterAccount = account }
                    }
                } label: {
                    Label(
                        filterAccount?.name ?? "All Accounts",
                        systemImage: "building.columns"
                    )
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(filterAccount != nil ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func deleteTransaction(_ transaction: Transaction) {
        do {
            let viewModel = TransactionViewModel(modelContext: modelContext)
            try viewModel.deleteTransaction(transaction)
        } catch {
            print("Failed to delete transaction: \(error)")
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
