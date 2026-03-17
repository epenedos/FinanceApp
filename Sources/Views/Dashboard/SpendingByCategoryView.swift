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
            VStack(spacing: 20) {
                periodPicker

                if categoryData.isEmpty {
                    ContentUnavailableView {
                        Label("No Expenses", systemImage: "chart.pie")
                    } description: {
                        Text("No expense data for the selected period.")
                    }
                } else {
                    totalCard
                    chartSection
                    categoryBreakdown
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
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

    private var totalCard: some View {
        VStack(spacing: 4) {
            Text("Total Spending")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(CurrencyFormatter.displayString(
                cents: totalSpending,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        }
    }

    private var chartSection: some View {
        Chart(categoryData, id: \.category.id) { item in
            SectorMark(
                angle: .value("Amount", item.totalCents),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(item.category.color.gradient)
            .annotation(position: .overlay) {
                let percentage = Double(item.totalCents) / Double(max(totalSpending, 1)) * 100
                if percentage >= 8 {
                    Text("\(Int(percentage))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(height: 260)
        .padding(.vertical, 8)
    }

    private var categoryBreakdown: some View {
        VStack(spacing: 2) {
            ForEach(categoryData, id: \.category.id) { item in
                let percentage = Double(item.totalCents) / Double(max(totalSpending, 1)) * 100

                HStack(spacing: 14) {
                    Image(systemName: item.category.icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(item.category.color.gradient)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.category.name)
                            .font(.subheadline.weight(.medium))

                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(item.category.color.gradient)
                                .frame(
                                    width: geometry.size.width * CGFloat(percentage / 100),
                                    height: 4
                                )
                        }
                        .frame(height: 4)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.displayString(
                            cents: item.totalCents,
                            currencyCode: AppConstants.defaultCurrencyCode
                        ))
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))

                        Text("\(Int(percentage))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
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
