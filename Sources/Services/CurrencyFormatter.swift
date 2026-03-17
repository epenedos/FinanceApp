import Foundation

struct CurrencyFormatter {
    private init() {}

    /// Formats cents as a display string for the given currency code
    /// e.g., 12550, "USD" -> "$125.50"
    static func displayString(cents: Int64, currencyCode: String) -> String {
        let currency = SupportedCurrency(rawValue: currencyCode) ?? .usd
        let scale = currency.minorUnitScale
        let decimalValue = Decimal(cents) / Decimal(scale)

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current

        return formatter.string(from: decimalValue as NSDecimalNumber) ?? "\(currencyCode) \(decimalValue)"
    }

    /// Formats cents as a signed display string (+ for income, - for expense)
    static func signedDisplayString(
        cents: Int64,
        currencyCode: String,
        transactionType: TransactionType
    ) -> String {
        let formatted = displayString(cents: cents, currencyCode: currencyCode)
        switch transactionType {
        case .income: return "+\(formatted)"
        case .expense: return "-\(formatted)"
        }
    }

    /// Parses a user-entered string into cents for the given currency
    /// Returns nil if the string cannot be parsed
    static func parseToCents(input: String, currencyCode: String) -> Int64? {
        let currency = SupportedCurrency(rawValue: currencyCode) ?? .usd
        let cleaned = input
            .replacingOccurrences(of: currency.symbol, with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let value = Decimal(string: cleaned) else { return nil }
        return value.toCents(scale: currency.minorUnitScale)
    }
}
