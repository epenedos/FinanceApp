import Foundation

// MARK: - Account Type

enum AccountType: String, Codable, CaseIterable, Identifiable {
    case checking
    case savings
    case creditCard
    case cash
    case investment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .checking: "Checking"
        case .savings: "Savings"
        case .creditCard: "Credit Card"
        case .cash: "Cash"
        case .investment: "Investment"
        }
    }

    var defaultIcon: String {
        switch self {
        case .checking: "building.columns"
        case .savings: "banknote"
        case .creditCard: "creditcard"
        case .cash: "dollarsign.circle"
        case .investment: "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Transaction Type

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .income: "Income"
        case .expense: "Expense"
        }
    }
}

// MARK: - Supported Currency

enum SupportedCurrency: String, Codable, CaseIterable, Identifiable {
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"
    case jpy = "JPY"
    case cad = "CAD"
    case aud = "AUD"
    case chf = "CHF"
    case cny = "CNY"
    case inr = "INR"
    case mxn = "MXN"
    case brl = "BRL"
    case krw = "KRW"
    case sek = "SEK"
    case nok = "NOK"
    case dkk = "DKK"

    var id: String { rawValue }

    var displayName: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: rawValue]))
        let name = locale.localizedString(forCurrencyCode: rawValue) ?? rawValue
        return "\(symbol) \(name) (\(rawValue))"
    }

    var symbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rawValue
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: 0) ?? rawValue
        return String(formatted.filter { !$0.isNumber && $0 != "." && $0 != "," }).trimmingCharacters(in: .whitespaces)
    }

    /// Number of minor units (cents) per major unit
    var minorUnitScale: Int {
        switch self {
        case .jpy, .krw: 1   // No decimal places
        default: 100          // 2 decimal places
        }
    }
}
