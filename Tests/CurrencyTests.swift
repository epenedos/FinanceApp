import Testing
import Foundation
@testable import FinanceApp

@Suite("Currency Formatting Tests")
struct CurrencyTests {

    @Test("Int64 cents converts to Decimal correctly")
    func centsToCurrencyDecimal() {
        let cents: Int64 = 12550
        let decimal = cents.toCurrencyDecimal(scale: 100)
        #expect(decimal == Decimal(string: "125.50"))
    }

    @Test("Decimal converts to cents correctly")
    func decimalToCents() {
        let decimal = Decimal(string: "125.50")!
        let cents = decimal.toCents(scale: 100)
        #expect(cents == 12550)
    }

    @Test("Zero cents returns zero decimal")
    func zeroCents() {
        let cents: Int64 = 0
        let decimal = cents.toCurrencyDecimal(scale: 100)
        #expect(decimal == Decimal.zero)
    }

    @Test("Japanese Yen has no decimal places")
    func yenScale() {
        let currency = SupportedCurrency.jpy
        #expect(currency.minorUnitScale == 1)
    }

    @Test("USD has 100 minor units")
    func usdScale() {
        let currency = SupportedCurrency.usd
        #expect(currency.minorUnitScale == 100)
    }

    @Test("CurrencyFormatter.parseToCents parses numeric input")
    func parseToCents() {
        let cents = CurrencyFormatter.parseToCents(input: "125.50", currencyCode: "USD")
        #expect(cents == 12550)
    }

    @Test("CurrencyFormatter.parseToCents returns nil for invalid input")
    func parseToCentsInvalid() {
        let cents = CurrencyFormatter.parseToCents(input: "abc", currencyCode: "USD")
        #expect(cents == nil)
    }
}

@Suite("Account Balance Tests")
struct AccountBalanceTests {

    @Test("Account type enum mapping works")
    func accountTypeMapping() {
        for type in AccountType.allCases {
            #expect(AccountType(rawValue: type.rawValue) == type)
        }
    }

    @Test("Transaction type enum mapping works")
    func transactionTypeMapping() {
        for type in TransactionType.allCases {
            #expect(TransactionType(rawValue: type.rawValue) == type)
        }
    }

    @Test("All supported currencies have valid raw values")
    func currencyCodes() {
        for currency in SupportedCurrency.allCases {
            #expect(currency.rawValue.count == 3)
        }
    }
}
