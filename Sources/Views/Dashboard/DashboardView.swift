import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
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

    private var isCompact: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }

    var body: some View {
        ScrollView {
            if isCompact {
                compactBody
            } else {
                regularBody
            }
        }
        .background(backgroundFill)
        .navigationTitle("Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(isCompact ? .inline : .large)
        #endif
        .sheet(isPresented: $showingAddTransaction) {
            TransactionFormView(transaction: nil)
        }
        .sheet(isPresented: $showingTransfer) {
            TransferFormView()
        }
    }

    // MARK: - Compact iPhone Layout

    private var compactBody: some View {
        VStack(spacing: 0) {
            // Hero balance area — full width, no padding
            compactBalanceHeader

            VStack(spacing: 12) {
                monthlyRow
                quickActions
                chartsRow
                accountsCard
                recentCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }

    private var compactBalanceHeader: some View {
        VStack(spacing: 2) {
            Text("Total Balance")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.displayString(
                cents: totalBalance,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .foregroundColor(totalBalance >= 0 ? .primary : .red)
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.12),
                    Color.accentColor.opacity(0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Regular / Wide Layout (iPad & macOS)

    private var regularBody: some View {
        VStack(spacing: 16) {
            // Top row: balance + monthly summary side by side
            HStack(spacing: 16) {
                regularBalanceCard
                monthlyOverviewCard
            }

            quickActions

            chartsRow

            // Bottom row: accounts + recent transactions side by side
            HStack(alignment: .top, spacing: 16) {
                accountsCard
                    .frame(maxWidth: .infinity)
                recentCard
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .padding(.bottom, 16)
    }

    private var regularBalanceCard: some View {
        VStack(spacing: 4) {
            Text("Total Balance")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

            Text(CurrencyFormatter.displayString(
                cents: totalBalance,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundColor(totalBalance >= 0 ? .primary : .red)
            .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(cardShape)
    }

    // MARK: - Monthly Summary

    private var monthlyRow: some View {
        HStack(spacing: 0) {
            monthlyStat(title: "Income", cents: currentMonthIncome, color: .green)
            thinDivider
            monthlyStat(title: "Expenses", cents: currentMonthExpenses, color: .red)
            thinDivider
            let net = currentMonthIncome - currentMonthExpenses
            monthlyStat(title: "Net", cents: net, color: net >= 0 ? .green : .red)
        }
        .padding(.vertical, 12)
        .background(cardShape)
    }

    private var monthlyOverviewCard: some View {
        HStack(spacing: 0) {
            monthlyStat(title: "Income", cents: currentMonthIncome, color: .green)
            thinDivider
            monthlyStat(title: "Expenses", cents: currentMonthExpenses, color: .red)
            thinDivider
            let net = currentMonthIncome - currentMonthExpenses
            monthlyStat(title: "Net", cents: net, color: net >= 0 ? .green : .red)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(cardShape)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 32)
    }

    private func monthlyStat(title: String, cents: Int64, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text(CurrencyFormatter.displayString(
                cents: cents,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(isCompact ? .caption : .subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                showingAddTransaction = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Transaction")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(.white)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)

            Button {
                showingTransfer = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Transfer")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(Color.accentColor)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Charts Row

    private var chartsRow: some View {
        HStack(spacing: 10) {
            NavigationLink {
                SankeyDiagramView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Money Flow")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 38)
                .foregroundStyle(.primary)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            NavigationLink {
                SpendingByCategoryView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie")
                    Text("Spending")
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 38)
                .foregroundStyle(.primary)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Accounts Card

    private var accountsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Accounts")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 8)

            if accounts.isEmpty {
                emptyRow(icon: "building.columns", text: "No accounts yet")
            } else {
                ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                    if index > 0 {
                        Divider().padding(.leading, 50)
                    }
                    NavigationLink {
                        AccountDetailView(account: account)
                    } label: {
                        accountRow(account)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer().frame(height: 8)
        }
        .background(cardShape)
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 10) {
            Image(systemName: account.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 7))

            Text(account.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(CurrencyFormatter.displayString(
                cents: account.balanceInCents,
                currencyCode: account.currency
            ))
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundColor(account.balanceInCents >= 0 ? .primary : .red)
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Recent Transactions Card

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                NavigationLink {
                    TransactionListView()
                } label: {
                    Text("See All")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if recentTransactions.isEmpty {
                emptyRow(icon: "list.bullet.rectangle", text: "No transactions yet")
            } else {
                ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, tx in
                    if index > 0 {
                        Divider().padding(.leading, 50)
                    }
                    TransactionRowView(
                        transaction: tx,
                        currencyCode: tx.account?.currency ?? AppConstants.defaultCurrencyCode
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
            }

            Spacer().frame(height: 8)
        }
        .background(cardShape)
    }

    // MARK: - Shared Helpers

    private var backgroundFill: Color {
        colorScheme == .dark
            ? Color(white: 0.07)
            : Color(white: 0.945)
    }

    private var cardFill: Color {
        colorScheme == .dark
            ? Color(white: 0.13)
            : Color.white
    }

    private var cardShape: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(cardFill)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 6, y: 2)
    }

    private func emptyRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.tertiary)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
