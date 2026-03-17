import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    let currencyCode: String

    var body: some View {
        HStack(spacing: 12) {
            categoryIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(transaction.date.shortFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            Text(formattedAmount)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(amountColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 2)
    }

    private var categoryIcon: some View {
        let iconName = transaction.isTransfer
            ? "arrow.left.arrow.right"
            : (transaction.category?.icon ?? "tag")
        let iconColor = transaction.isTransfer
            ? Color.gray
            : (transaction.category?.color ?? .accentColor)

        return Image(systemName: iconName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(iconColor.gradient)
            .clipShape(Circle())
    }

    private var displayTitle: String {
        if transaction.isTransfer {
            return transaction.notes.isEmpty ? "Transfer" : transaction.notes
        }
        return transaction.notes.isEmpty
            ? (transaction.category?.name ?? "Uncategorized")
            : transaction.notes
    }

    private var formattedAmount: String {
        CurrencyFormatter.signedDisplayString(
            cents: transaction.amountInCents,
            currencyCode: currencyCode,
            transactionType: transaction.transactionTypeEnum
        )
    }

    private var amountColor: Color {
        transaction.transactionTypeEnum == .income ? .green : .red
    }
}
