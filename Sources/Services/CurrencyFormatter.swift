import Foundation

enum AppCurrency: String, CaseIterable, Identifiable, Codable {
    case tryCurrency = "TRY"
    case usd = "USD"
    case eur = "EUR"
    case gbp = "GBP"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .tryCurrency: return "₺"
        case .usd: return "$"
        case .eur: return "€"
        case .gbp: return "£"
        }
    }
}

enum CurrencyFormatter {
    static func format(_ amount: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .current
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currencyCode)"
    }
}
