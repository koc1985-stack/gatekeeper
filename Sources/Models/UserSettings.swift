import Foundation
import SwiftData

enum IncomeEntryMode: String, Codable {
    case hourly
    case monthly
}

enum NightChallenge: String, Codable, CaseIterable, Identifiable {
    case hold
    case math

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .hold: return "15 saniye bekle"
        case .math: return "Matematik sorusu"
        }
    }
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
    var nightModeEnabled: Bool = false
    var nightModeStartHour: Int = 23
    var nightModeEndHour: Int = 5
    var nightChallengeRaw: String = NightChallenge.hold.rawValue

    init() {}

    var incomeEntryMode: IncomeEntryMode {
        get { IncomeEntryMode(rawValue: incomeEntryModeRaw) ?? .hourly }
        set { incomeEntryModeRaw = newValue.rawValue }
    }

    var nightChallenge: NightChallenge {
        get { NightChallenge(rawValue: nightChallengeRaw) ?? .hold }
        set { nightChallengeRaw = newValue.rawValue }
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

    /// Whether the current moment falls inside the configured night window (wraps past midnight).
    func isCurrentlyNight(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard nightModeEnabled else { return false }
        let hour = calendar.component(.hour, from: now)
        if nightModeStartHour == nightModeEndHour { return false }
        if nightModeStartHour < nightModeEndHour {
            return hour >= nightModeStartHour && hour < nightModeEndHour
        } else {
            // Window wraps past midnight, e.g. 23 -> 5.
            return hour >= nightModeStartHour || hour < nightModeEndHour
        }
    }
}
