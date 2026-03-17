import Foundation
import SwiftUI

// MARK: - Int64 Currency Extensions

extension Int64 {
    /// Converts cents to a Decimal representation (e.g., 12550 -> 125.50)
    func toCurrencyDecimal(scale: Int = 100) -> Decimal {
        Decimal(self) / Decimal(scale)
    }
}

// MARK: - Decimal Currency Extensions

extension Decimal {
    /// Converts a Decimal to cents (e.g., 125.50 -> 12550)
    func toCents(scale: Int = 100) -> Int64 {
        let scaled = self * Decimal(scale)
        return Int64(truncating: scaled as NSDecimalNumber)
    }
}

// MARK: - Color Hex Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }

    func toHex() -> String {
        #if os(macOS)
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        #else
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        #endif
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
