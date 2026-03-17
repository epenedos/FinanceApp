import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.createdDate) private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var showingAddTransaction = false
    @State private var showingTransfer = false

    private var dashboardVM: DashboardViewModel {
        DashboardViewModel(modelContext: modelContext)
    }

    private var totalBalance: Int64 {
        dashboardVM.totalBalance(accounts: accounts)
    }

    private var currentMonthIncome: Int64 {
        dashboardVM.monthlyIncome(transactions: Array(allTransactions), month: .now)
    }

    private var currentMonthExpenses: Int64 {
        dashboardVM.monthlyExpenses(transactions: Array(allTransactions), month: .now)
    }

    private var recentTransactions: [Transaction] {
        dashboardVM.recentTransactions(transactions: Array(allTransactions))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                netWorthCard
                monthlyOverviewCard
                quickActions
                accountsSection
                recentTransactionsSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .sheet(isPresented: $showingAddTransaction) {
            TransactionFormView(transaction: nil)
        }
        .sheet(isPresented: $showingTransfer) {
            TransferFormView()
        }
    }

    private var netWorthCard: some View {
        VStack(spacing: 8) {
            Text("Net Worth")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.displayString(
                cents: totalBalance,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.largeTitle.bold())
            .foregroundColor(totalBalance >= 0 ? .primary : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var monthlyOverviewCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Income")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.displayString(
                    cents: currentMonthIncome,
                    currencyCode: AppConstants.defaultCurrencyCode
                ))
                .font(.headline)
                .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Text("Expenses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.displayString(
                    cents: currentMonthExpenses,
                    currencyCode: AppConstants.defaultCurrencyCode
                ))
                .font(.headline)
                .foregroundStyle(.red)
            }
            .frame(maxWidth: .infinity)

            Divider().frame(height: 40)

            VStack(spacing: 4) {
                Text("Net")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                let net = currentMonthIncome - currentMonthExpenses
                Text(CurrencyFormatter.displayString(
                    cents: net,
                    currencyCode: AppConstants.defaultCurrencyCode
                ))
                .font(.headline)
                .foregroundColor(net >= 0 ? .green : .red)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                showingAddTransaction = true
            } label: {
                Label("Add Transaction", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                showingTransfer = true
            } label: {
                Label("Transfer", systemImage: "arrow.left.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accounts")
                .font(.headline)

            if accounts.isEmpty {
                Text("No accounts yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(accounts) { account in
                    HStack {
                        Image(systemName: account.icon)
                            .foregroundStyle(.tint)
                            .frame(width: 24)

                        Text(account.name)
                            .font(.body)

                        Spacer()

                        Text(CurrencyFormatter.displayString(
                            cents: account.balanceInCents,
                            currencyCode: account.currency
                        ))
                        .font(.body.bold())
                        .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    TransactionListView()
                }
                .font(.caption)
            }

            if recentTransactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentTransactions) { transaction in
                    TransactionRowView(
                        transaction: transaction,
                        currencyCode: transaction.account?.currency ?? AppConstants.defaultCurrencyCode
                    )
                    .padding(.vertical, 4)
                    .padding(.horizontal, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}
