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

    /// Group transactions by date section (Today, Yesterday, This Week, etc.)
    private var groupedTransactions: [(key: String, transactions: [Transaction])] {
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        var groups: [String: [Transaction]] = [:]
        let groupOrder = ["Today", "Yesterday", "This Week", "Earlier"]

        for transaction in filteredTransactions {
            let txDate = calendar.startOfDay(for: transaction.date)
            let key: String
            if txDate >= today {
                key = "Today"
            } else if txDate >= yesterday {
                key = "Yesterday"
            } else if txDate >= weekAgo {
                key = "This Week"
            } else {
                key = "Earlier"
            }
            groups[key, default: []].append(transaction)
        }

        return groupOrder.compactMap { key in
            guard let transactions = groups[key], !transactions.isEmpty else { return nil }
            return (key: key, transactions: transactions)
        }
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
        .searchable(text: $searchText, prompt: "Search by notes or category")
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
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            if filteredTransactions.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No matching transactions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
            } else {
                ForEach(groupedTransactions, id: \.key) { group in
                    Section(group.key) {
                        ForEach(group.transactions) { transaction in
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
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
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

                Rectangle()
                    .fill(.separator)
                    .frame(width: 1, height: 20)
                    .padding(.horizontal, 2)

                Menu {
                    Button("All Accounts") { filterAccount = nil }
                    ForEach(accounts) { account in
                        Button(account.name) { filterAccount = account }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "building.columns")
                        Text(filterAccount?.name ?? "All Accounts")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        filterAccount != nil
                            ? Color.accentColor.opacity(0.15)
                            : Color.secondary.opacity(0.15)
                    )
                    .clipShape(Capsule())
                }
            }
        }
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
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? Color.accentColor.opacity(0.15)
                        : Color.secondary.opacity(0.15)
                )
                .foregroundStyle(isSelected ? Color.accentColor : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
