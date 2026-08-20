import Foundation

/// Historical average annual returns — rough, well-known long-run estimates, not a guarantee.
/// Shown to the user with an explicit "geçmiş performans gelecek için garanti değildir" disclaimer.
enum InvestmentAsset: String, CaseIterable, Identifiable {
    case sp500
    case gold

    var id: String { rawValue }

    var annualReturnRate: Double {
        switch self {
        case .sp500: return 0.10
        case .gold: return 0.07
        }
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .sp500: return "S&P 500"
        case .gold: return "Altın"
        }
    }
}

enum WageCalculator {
    /// Converts a monthly net income into an hourly wage given a weekly working-hours figure.
    static func hourlyWage(fromMonthlyIncome monthly: Double, hoursPerWeek: Double) -> Double {
        guard hoursPerWeek > 0 else { return 0 }
        return (monthly * 12) / (hoursPerWeek * 52)
    }

    static func hoursRequired(price: Double, hourlyWage: Double) -> Double {
        guard hourlyWage > 0, price > 0 else { return 0 }
        return price / hourlyWage
    }

    /// Compound growth projection: what `principal` could become after `years` at `annualRate`.
    static func projectedValue(principal: Double, years: Double, annualRate: Double) -> Double {
        guard principal > 0, years > 0 else { return principal }
        return principal * pow(1 + annualRate, years)
    }

    /// Formats a duration of work as a short localized phrase, e.g. "35 dakika", "6.5 saat", "3 gün".
    static func formattedHours(_ hours: Double) -> String {
        guard hours > 0 else {
            return String(localized: "0 dakika")
        }
        if hours < 1 {
            let minutes = max(1, Int((hours * 60).rounded()))
            return String(localized: "\(minutes) dakika")
        } else if hours < 100 {
            let roundedText = String(format: "%.1f", (hours * 10).rounded() / 10)
            return String(localized: "\(roundedText) saat")
        } else {
            let days = Int((hours / 24).rounded())
            return String(localized: "\(days) gün")
        }
    }
}
