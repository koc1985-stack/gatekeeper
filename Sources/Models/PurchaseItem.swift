import Foundation
import SwiftData

enum PurchaseStatus: String, Codable, CaseIterable {
    case waiting
    case bought
    case skipped
}

enum Mood: String, Codable, CaseIterable, Identifiable {
    case stressed
    case sad
    case bored
    case happy

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .stressed: return "Stresli"
        case .sad: return "Üzgün"
        case .bored: return "Sıkılmış"
        case .happy: return "Mutlu"
        }
    }

    var emoji: String {
        switch self {
        case .stressed: return "😣"
        case .sad: return "😢"
        case .bored: return "🥱"
        case .happy: return "😊"
        }
    }
}

enum PurchaseSource: String, Codable, CaseIterable {
    case manual
    case extensionSource = "extension"
}

/// What actually put this item in front of the user — the "çevresel faktör" question.
enum PurchaseTrigger: String, Codable, CaseIterable, Identifiable {
    case ad
    case friend
    case store
    case browsing
    case other

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .ad: return "Sosyal medya reklamı"
        case .friend: return "Arkadaş önerisi"
        case .store: return "Mağazada/vitrinde gördüm"
        case .browsing: return "Sıkılıp gezerken denk geldim"
        case .other: return "Diğer"
        }
    }
}

/// "Bunu ne zamandır istiyorsun?" — az önce görülen bir şey mi, yoksa üzerine düşünülmüş bir istek mi.
/// En güçlü dürtüsellik sinyallerinden biri: düşünme süresi neredeyse sıfırsa risk yüksektir.
enum ConsiderationPeriod: String, Codable, CaseIterable, Identifiable {
    case justNow
    case fewDays
    case longTime

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .justNow: return "Az önce gördüm"
        case .fewDays: return "Birkaç gündür düşünüyorum"
        case .longTime: return "Uzun zamandır istiyorum"
        }
    }
}

/// "1 hafta sonra bu karardan memnun olur musun?" — beklenen pişmanlık (anticipated regret) sorusu.
/// Davranışsal ekonomide, geleceğe kısa bir zihinsel sıçrama yaptırmak dürtüsel kararları en çok
/// azaltan tekniklerden biridir; bu yüzden diğer sorulardan ayrı ve daha belirgin bir ağırlıkla ele alınır.
enum FutureOutlook: String, Codable, CaseIterable, Identifiable {
    case satisfied
    case unsure
    case regretLikely

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .satisfied: return "Evet, memnun olurum"
        case .unsure: return "Emin değilim"
        case .regretLikely: return "Muhtemelen pişman olurum"
        }
    }
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
    var moodRaw: String?
    var sourceRaw: String = PurchaseSource.manual.rawValue
    var sourceDomain: String?
    var isNeed: Bool?
    var alreadyOwnsSimilar: Bool?
    var triggerRaw: String?
    var considerationRaw: String?
    var futureOutlookRaw: String?

    init(
        name: String,
        price: Double,
        currencyCode: String,
        note: String = "",
        imageData: Data? = nil,
        category: PurchaseCategory = .other,
        cooldownHours: Double = 24,
        mood: Mood? = nil,
        source: PurchaseSource = .manual,
        sourceDomain: String? = nil,
        isNeed: Bool? = nil,
        alreadyOwnsSimilar: Bool? = nil,
        trigger: PurchaseTrigger? = nil,
        consideration: ConsiderationPeriod? = nil,
        futureOutlook: FutureOutlook? = nil
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
        self.moodRaw = mood?.rawValue
        self.sourceRaw = source.rawValue
        self.sourceDomain = sourceDomain
        self.isNeed = isNeed
        self.alreadyOwnsSimilar = alreadyOwnsSimilar
        self.triggerRaw = trigger?.rawValue
        self.considerationRaw = consideration?.rawValue
        self.futureOutlookRaw = futureOutlook?.rawValue
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

    var mood: Mood? {
        get { moodRaw.flatMap { Mood(rawValue: $0) } }
        set { moodRaw = newValue?.rawValue }
    }

    var source: PurchaseSource {
        get { PurchaseSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var trigger: PurchaseTrigger? {
        get { triggerRaw.flatMap { PurchaseTrigger(rawValue: $0) } }
        set { triggerRaw = newValue?.rawValue }
    }

    var consideration: ConsiderationPeriod? {
        get { considerationRaw.flatMap { ConsiderationPeriod(rawValue: $0) } }
        set { considerationRaw = newValue?.rawValue }
    }

    var futureOutlook: FutureOutlook? {
        get { futureOutlookRaw.flatMap { FutureOutlook(rawValue: $0) } }
        set { futureOutlookRaw = newValue?.rawValue }
    }
}
