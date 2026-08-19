import Foundation
import SwiftData

enum IncomeEntryMode: String, Codable {
    case hourly
    case monthly
}

@Model
final class UserSettings {
    var id: UUID = UUID()
    var hourlyWage: Double = 0
    var monthlyIncome: Double = 0
    var hoursPerWeek: Double = 45
    var incomeEntryModeRaw: String = IncomeEntryMode.hourly.rawValue
    var defaultCooldownHours: Double = 24
    var currencyCode: String = "TRY"
    var hasCompletedOnboarding: Bool = false
    var notificationsEnabled: Bool = false

    init() {}

    var incomeEntryMode: IncomeEntryMode {
        get { IncomeEntryMode(rawValue: incomeEntryModeRaw) ?? .hourly }
        set { incomeEntryModeRaw = newValue.rawValue }
    }

    /// The hourly wage actually used for calculations, derived from whichever entry mode the user chose.
    var effectiveHourlyWage: Double {
        switch incomeEntryMode {
        case .hourly:
            return hourlyWage
        case .monthly:
            return WageCalculator.hourlyWage(fromMonthlyIncome: monthlyIncome, hoursPerWeek: hoursPerWeek)
        }
    }
}
