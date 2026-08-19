import Foundation

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
