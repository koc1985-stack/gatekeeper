import Foundation
import SwiftData

enum PurchaseStatus: String, Codable, CaseIterable {
    case waiting
    case bought
    case skipped
}

enum PurchaseCategory: String, Codable, CaseIterable, Identifiable {
    case clothing
    case electronics
    case home
    case beauty
    case hobby
    case other

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .clothing: return "Giyim"
        case .electronics: return "Elektronik"
        case .home: return "Ev"
        case .beauty: return "Kozmetik"
        case .hobby: return "Hobi"
        case .other: return "Diğer"
        }
    }

    var symbolName: String {
        switch self {
        case .clothing: return "tshirt.fill"
        case .electronics: return "tv.fill"
        case .home: return "house.fill"
        case .beauty: return "sparkles"
        case .hobby: return "gamecontroller.fill"
        case .other: return "bag.fill"
        }
    }
}

@Model
final class PurchaseItem {
    var id: UUID = UUID()
    var name: String = ""
    var price: Double = 0
    var currencyCode: String = "TRY"
    var note: String = ""
    @Attribute(.externalStorage) var imageData: Data?
    var categoryRaw: String = PurchaseCategory.other.rawValue
    var createdAt: Date = Date.now
    var cooldownEndsAt: Date = Date.now
    var statusRaw: String = PurchaseStatus.waiting.rawValue
    var decidedAt: Date?

    init(
        name: String,
        price: Double,
        currencyCode: String,
        note: String = "",
        imageData: Data? = nil,
        category: PurchaseCategory = .other,
        cooldownHours: Double = 24
    ) {
        let now = Date.now
        self.id = UUID()
        self.name = name
        self.price = price
        self.currencyCode = currencyCode
        self.note = note
        self.imageData = imageData
        self.categoryRaw = category.rawValue
        self.createdAt = now
        self.cooldownEndsAt = now.addingTimeInterval(cooldownHours * 3600)
        self.statusRaw = PurchaseStatus.waiting.rawValue
        self.decidedAt = nil
    }

    var category: PurchaseCategory {
        get { PurchaseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: PurchaseStatus {
        get { PurchaseStatus(rawValue: statusRaw) ?? .waiting }
        set { statusRaw = newValue.rawValue }
    }

    var isWaiting: Bool { status == .waiting }

    var cooldownRemaining: TimeInterval {
        max(0, cooldownEndsAt.timeIntervalSinceNow)
    }

    var isCooldownComplete: Bool {
        cooldownEndsAt <= .now
    }
}
