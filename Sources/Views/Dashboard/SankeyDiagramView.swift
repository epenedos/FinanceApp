import SwiftUI
import SwiftData

// MARK: - Data Model

struct SankeyFlow: Identifiable {
    let id = UUID()
    let label: String
    let amount: Int64
    let color: Color
}

struct SankeyLayoutData {
    let incomeFlows: [SankeyFlow]
    let expenseFlows: [SankeyFlow]
    let savingsAmount: Int64
    let totalIncome: Int64
    let totalExpenses: Int64
}

// MARK: - Sankey Diagram View

struct SankeyDiagramView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
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

    private var layoutData: SankeyLayoutData {
        let range = dateRange
        let filtered = allTransactions.filter {
            $0.date >= range.from && $0.date <= range.to
        }

        // Group incomes by category
        var incomeByCategory: [String: (amount: Int64, color: Color, icon: String)] = [:]
        var expenseByCategory: [String: (amount: Int64, color: Color, icon: String)] = [:]

        for tx in filtered {
            let catName = tx.category?.name ?? "Other"
            let catColor = tx.category?.color ?? .gray
            let catIcon = tx.category?.icon ?? "tag"

            if tx.transactionType == TransactionType.income.rawValue {
                let existing = incomeByCategory[catName]
                incomeByCategory[catName] = (
                    amount: (existing?.amount ?? 0) + tx.amountInCents,
                    color: catColor,
                    icon: catIcon
                )
            } else if tx.transactionType == TransactionType.expense.rawValue {
                let existing = expenseByCategory[catName]
                expenseByCategory[catName] = (
                    amount: (existing?.amount ?? 0) + tx.amountInCents,
                    color: catColor,
                    icon: catIcon
                )
            }
        }

        let incomeFlows = incomeByCategory
            .map { SankeyFlow(label: $0.key, amount: $0.value.amount, color: $0.value.color) }
            .sorted { $0.amount > $1.amount }

        let expenseFlows = expenseByCategory
            .map { SankeyFlow(label: $0.key, amount: $0.value.amount, color: $0.value.color) }
            .sorted { $0.amount > $1.amount }

        let totalIncome = incomeFlows.reduce(Int64(0)) { $0 + $1.amount }
        let totalExpenses = expenseFlows.reduce(Int64(0)) { $0 + $1.amount }
        let savings = max(totalIncome - totalExpenses, 0)

        return SankeyLayoutData(
            incomeFlows: incomeFlows,
            expenseFlows: expenseFlows,
            savingsAmount: savings,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                periodPicker

                if layoutData.totalIncome == 0 && layoutData.totalExpenses == 0 {
                    ContentUnavailableView {
                        Label("No Data", systemImage: "chart.bar.xaxis")
                    } description: {
                        Text("Add income and expense transactions to see the money flow.")
                    }
                } else {
                    summaryRow
                    sankeyChart
                    legendSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(white: colorScheme == .dark ? 0.07 : 0.945))
        .navigationTitle("Money Flow")
    }

    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(TimePeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryRow: some View {
        HStack(spacing: 0) {
            summaryItem(
                label: "Income",
                cents: layoutData.totalIncome,
                color: .green
            )
            summaryDivider
            summaryItem(
                label: "Expenses",
                cents: layoutData.totalExpenses,
                color: .red
            )
            summaryDivider
            summaryItem(
                label: "Savings",
                cents: layoutData.savingsAmount,
                color: .blue
            )
        }
        .padding(.vertical, 14)
        .background(cardShape)
    }

    private var summaryDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 1, height: 32)
    }

    private func summaryItem(label: String, cents: Int64, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(CurrencyFormatter.displayString(
                cents: cents,
                currencyCode: AppConstants.defaultCurrencyCode
            ))
            .font(.system(.footnote, design: .rounded, weight: .bold))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sankey Chart

    private var sankeyChart: some View {
        GeometryReader { geometry in
            let size = geometry.size
            SankeyCanvas(data: layoutData, size: size, colorScheme: colorScheme)
        }
        .frame(height: sankeyHeight)
        .padding(.vertical, 12)
        .background(cardShape)
    }

    private var sankeyHeight: CGFloat {
        let maxNodes = max(layoutData.incomeFlows.count, layoutData.expenseFlows.count + 1)
        return CGFloat(max(maxNodes, 3)) * 52 + 40
    }

    // MARK: - Legend

    private var legendSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breakdown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                if !layoutData.incomeFlows.isEmpty {
                    legendGroup(title: "Income", flows: layoutData.incomeFlows, total: layoutData.totalIncome)
                }
                if !layoutData.expenseFlows.isEmpty {
                    if !layoutData.incomeFlows.isEmpty {
                        Divider().padding(.vertical, 4)
                    }
                    legendGroup(title: "Expenses", flows: layoutData.expenseFlows, total: layoutData.totalExpenses)
                }
            }
            .padding(.vertical, 8)
            .background(cardShape)
        }
    }

    private func legendGroup(title: String, flows: [SankeyFlow], total: Int64) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)

            ForEach(flows) { flow in
                HStack(spacing: 10) {
                    Circle()
                        .fill(flow.color.gradient)
                        .frame(width: 10, height: 10)

                    Text(flow.label)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    let pct = total > 0 ? Double(flow.amount) / Double(total) * 100 : 0
                    Text("\(Int(pct))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)

                    Text(CurrencyFormatter.displayString(
                        cents: flow.amount,
                        currencyCode: AppConstants.defaultCurrencyCode
                    ))
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .frame(minWidth: 80, alignment: .trailing)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
            }
        }
    }

    // MARK: - Card Background

    private var cardShape: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 6, y: 2)
    }
}

// MARK: - Sankey Canvas (Custom Drawing)

private struct SankeyCanvas: View {
    let data: SankeyLayoutData
    let size: CGSize
    let colorScheme: ColorScheme

    // Layout constants
    private let nodeWidth: CGFloat = 14
    private let nodePadding: CGFloat = 8
    private let labelWidth: CGFloat = 90

    private var drawableWidth: CGFloat {
        size.width - labelWidth * 2 - 32
    }

    private var centerX: CGFloat { size.width / 2 }

    // Column positions
    private var leftNodeX: CGFloat { labelWidth + 16 }
    private var centerNodeX: CGFloat { centerX - nodeWidth / 2 }
    private var rightNodeX: CGFloat { size.width - labelWidth - 16 - nodeWidth }

    var body: some View {
        ZStack {
            // Draw links
            linksLayer

            // Draw nodes
            nodesLayer

            // Draw labels
            labelsLayer
        }
    }

    // MARK: - Links

    private var linksLayer: some View {
        Canvas { context, canvasSize in
            let totalFlow = max(data.totalIncome, data.totalExpenses, 1)
            let availableHeight = canvasSize.height - 20
            let scale = availableHeight / CGFloat(totalFlow)

            // Income → Center links
            var incomeY: CGFloat = 10
            var centerLeftY: CGFloat = 10

            for flow in data.incomeFlows {
                let thickness = CGFloat(flow.amount) * scale
                let fromY = incomeY + thickness / 2
                let toY = centerLeftY + thickness / 2

                let path = bezierLink(
                    fromX: leftNodeX + nodeWidth,
                    fromY: fromY,
                    toX: centerNodeX,
                    toY: toY,
                    thickness: thickness
                )

                context.fill(
                    path,
                    with: .color(flow.color.opacity(0.3))
                )
                context.stroke(
                    path,
                    with: .color(flow.color.opacity(0.1)),
                    lineWidth: 0.5
                )

                incomeY += thickness + nodePadding
                centerLeftY += thickness + nodePadding
            }

            // Center → Expense links
            var centerRightY: CGFloat = 10
            var expenseY: CGFloat = 10

            // Expense flows
            for flow in data.expenseFlows {
                let thickness = CGFloat(flow.amount) * scale
                let fromY = centerRightY + thickness / 2
                let toY = expenseY + thickness / 2

                let path = bezierLink(
                    fromX: centerNodeX + nodeWidth,
                    fromY: fromY,
                    toX: rightNodeX,
                    toY: toY,
                    thickness: thickness
                )

                context.fill(
                    path,
                    with: .color(flow.color.opacity(0.3))
                )

                centerRightY += thickness + nodePadding
                expenseY += thickness + nodePadding
            }

            // Savings link (if any)
            if data.savingsAmount > 0 {
                let thickness = CGFloat(data.savingsAmount) * scale
                let fromY = centerRightY + thickness / 2
                let toY = expenseY + thickness / 2

                let path = bezierLink(
                    fromX: centerNodeX + nodeWidth,
                    fromY: fromY,
                    toX: rightNodeX,
                    toY: toY,
                    thickness: thickness
                )

                context.fill(
                    path,
                    with: .color(Color.blue.opacity(0.3))
                )
            }
        }
    }

    private func bezierLink(
        fromX: CGFloat,
        fromY: CGFloat,
        toX: CGFloat,
        toY: CGFloat,
        thickness: CGFloat
    ) -> Path {
        let halfT = thickness / 2
        let midX = (fromX + toX) / 2

        var path = Path()

        // Top edge
        path.move(to: CGPoint(x: fromX, y: fromY - halfT))
        path.addCurve(
            to: CGPoint(x: toX, y: toY - halfT),
            control1: CGPoint(x: midX, y: fromY - halfT),
            control2: CGPoint(x: midX, y: toY - halfT)
        )

        // Right edge down
        path.addLine(to: CGPoint(x: toX, y: toY + halfT))

        // Bottom edge (reverse)
        path.addCurve(
            to: CGPoint(x: fromX, y: fromY + halfT),
            control1: CGPoint(x: midX, y: toY + halfT),
            control2: CGPoint(x: midX, y: fromY + halfT)
        )

        path.closeSubpath()
        return path
    }

    // MARK: - Nodes

    private var nodesLayer: some View {
        Canvas { context, canvasSize in
            let totalFlow = max(data.totalIncome, data.totalExpenses, 1)
            let availableHeight = canvasSize.height - 20
            let scale = availableHeight / CGFloat(totalFlow)

            // Income nodes (left)
            var y: CGFloat = 10
            for flow in data.incomeFlows {
                let h = CGFloat(flow.amount) * scale
                let rect = CGRect(x: leftNodeX, y: y, width: nodeWidth, height: h)
                let rounded = Path(roundedRect: rect, cornerRadius: 4)
                context.fill(rounded, with: .color(flow.color))
                y += h + nodePadding
            }

            // Center node
            let centerHeight = CGFloat(totalFlow) * scale +
                CGFloat(max(data.incomeFlows.count - 1, 0)) * nodePadding
            let centerRect = CGRect(
                x: centerNodeX,
                y: 10,
                width: nodeWidth,
                height: centerHeight
            )
            let centerRounded = Path(roundedRect: centerRect, cornerRadius: 4)
            let centerColor = colorScheme == .dark ? Color.white.opacity(0.3) : Color.gray.opacity(0.4)
            context.fill(centerRounded, with: .color(centerColor))

            // Expense nodes (right)
            y = 10
            for flow in data.expenseFlows {
                let h = CGFloat(flow.amount) * scale
                let rect = CGRect(x: rightNodeX, y: y, width: nodeWidth, height: h)
                let rounded = Path(roundedRect: rect, cornerRadius: 4)
                context.fill(rounded, with: .color(flow.color))
                y += h + nodePadding
            }

            // Savings node
            if data.savingsAmount > 0 {
                let h = CGFloat(data.savingsAmount) * scale
                let rect = CGRect(x: rightNodeX, y: y, width: nodeWidth, height: h)
                let rounded = Path(roundedRect: rect, cornerRadius: 4)
                context.fill(rounded, with: .color(.blue))
                y += h + nodePadding
            }
        }
    }

    // MARK: - Labels

    private var labelsLayer: some View {
        Canvas { context, canvasSize in
            let totalFlow = max(data.totalIncome, data.totalExpenses, 1)
            let availableHeight = canvasSize.height - 20
            let scale = availableHeight / CGFloat(totalFlow)

            let labelColor = colorScheme == .dark ? Color.white.opacity(0.85) : Color.black.opacity(0.75)

            // Income labels (left-aligned, to the left of nodes)
            var y: CGFloat = 10
            for flow in data.incomeFlows {
                let h = CGFloat(flow.amount) * scale
                let centerY = y + h / 2

                let text = Text(flow.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(labelColor)

                context.draw(
                    text,
                    at: CGPoint(x: leftNodeX - 6, y: centerY),
                    anchor: .trailing
                )
                y += h + nodePadding
            }

            // Center label
            let centerHeight = CGFloat(totalFlow) * scale +
                CGFloat(max(data.incomeFlows.count - 1, 0)) * nodePadding
            let budgetText = Text("Budget")
                .font(.caption2.weight(.bold))
                .foregroundStyle(labelColor)
            context.draw(
                budgetText,
                at: CGPoint(x: centerX, y: 10 + centerHeight / 2),
                anchor: .center
            )

            // Expense labels (right-aligned, to the right of nodes)
            y = 10
            for flow in data.expenseFlows {
                let h = CGFloat(flow.amount) * scale
                let centerY = y + h / 2

                let text = Text(flow.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(labelColor)

                context.draw(
                    text,
                    at: CGPoint(x: rightNodeX + nodeWidth + 6, y: centerY),
                    anchor: .leading
                )
                y += h + nodePadding
            }

            // Savings label
            if data.savingsAmount > 0 {
                let h = CGFloat(data.savingsAmount) * scale
                let centerY = y + h / 2

                let text = Text("Savings")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.blue)

                context.draw(
                    text,
                    at: CGPoint(x: rightNodeX + nodeWidth + 6, y: centerY),
                    anchor: .leading
                )
            }
        }
    }
}
