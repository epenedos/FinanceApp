import SwiftUI
import SwiftData
import Charts

struct SpendingByCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var selectedPeriod: TimePeriod = .thisMonth

    private var dashboardVM: DashboardViewModel {
        DashboardViewModel(modelContext: modelContext)
    }

    private var dateRange: (from: Date, to: Date) {
        let now = Date.now
        switch selectedPeriod {
        case .thisMonth:
            return (now.startOfMonth, now.endOfMonth)
        case .lastMonth:
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
            return (lastMonth.startOfMonth, lastMonth.endOfMonth)
        case .last3Months:
            let threeMonthsAgo = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
            return (threeMonthsAgo.startOfMonth, now.endOfMonth)
        }
    }

    private var categoryData: [(category: Category, totalCents: Int64)] {
        let range = dateRange
        return dashboardVM.spendingByCategory(
            transactions: Array(allTransactions),
            from: range.from,
            to: range.to
        )
    }

    private var totalSpending: Int64 {
        categoryData.reduce(Int64(0)) { $0 + $1.totalCents }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                periodPicker

                if categoryData.isEmpty {
                    ContentUnavailableView {
                        Label("No Expenses", systemImage: "chart.pie")
                    } description: {
                        Text("No expense data for the selected period.")
                    }
                } else {
                    chartSection
                    categoryBreakdown
                }
            }
            .padding()
        }
        .navigationTitle("Spending by Category")
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var chartSection: some View {
        Chart(categoryData, id: \.category.id) { item in
            SectorMark(
                angle: .value("Amount", item.totalCents),
                innerRadius: .ratio(0.5),
                angularInset: 1
            )
            .foregroundStyle(item.category.color)
            .annotation(position: .overlay) {
                let percentage = Double(item.totalCents) / Double(max(totalSpending, 1)) * 100
                if percentage >= 8 {
                    Text("\(Int(percentage))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 240)
    }

    private var categoryBreakdown: some View {
        VStack(spacing: 8) {
            ForEach(categoryData, id: \.category.id) { item in
                HStack(spacing: 12) {
                    Image(systemName: item.category.icon)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(item.category.color)
                        .clipShape(Circle())

                    Text(item.category.name)
                        .font(.body)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.displayString(
                            cents: item.totalCents,
                            currencyCode: AppConstants.defaultCurrencyCode
                        ))
                        .font(.body.bold())

                        let percentage = Double(item.totalCents) / Double(max(totalSpending, 1)) * 100
                        Text("\(Int(percentage))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

enum TimePeriod: String, CaseIterable, Identifiable {
    case thisMonth
    case lastMonth
    case last3Months

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thisMonth: "This Month"
        case .lastMonth: "Last Month"
        case .last3Months: "3 Months"
        }
    }
}
