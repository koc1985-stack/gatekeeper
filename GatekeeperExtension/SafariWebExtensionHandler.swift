import Foundation
import SafariServices
import SwiftData
import WidgetKit

/// Bridges the Safari Web Extension's JS content script (which cannot touch SwiftData directly)
/// to the shared App Group store. One request in, one JSON-ish response out.
///
/// Deliberately does NOT schedule the 24h local notification here: notification permission/UI
/// isn't reliably available from a headless extension process. Instead the main app reconciles
/// (schedules any missing reminder) every time it becomes active — see RootView.reconcileNotifications.
final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    private let modelContainer = SharedModelContainer.make()

    func beginRequest(with context: NSExtensionContext) {
        guard
            let item = context.inputItems.first as? NSExtensionItem,
            let message = item.userInfo?[SFExtensionMessageKey] as? [String: Any],
            let type = message["type"] as? String
        else {
            complete(context: context, response: ["ok": false, "error": "invalid_message"])
            return
        }

        let payload = message["data"] as? [String: Any] ?? [:]
        let modelContext = ModelContext(modelContainer)

        switch type {
        case "getWageInfo":
            let settings = fetchOrCreateSettings(in: modelContext)
            complete(context: context, response: [
                "ok": true,
                "hourlyWage": settings.effectiveHourlyWage,
                "monthlyIncome": settings.effectiveMonthlyIncome,
                "currencyCode": settings.currencyCode
            ])

        case "getNightModeConfig":
            let settings = fetchOrCreateSettings(in: modelContext)
            complete(context: context, response: [
                "ok": true,
                "enabled": settings.nightModeEnabled,
                "startHour": settings.nightModeStartHour,
                "endHour": settings.nightModeEndHour,
                "challenge": settings.nightChallenge.rawValue,
                "isNight": settings.isCurrentlyNight()
            ])

        case "lockItem":
            handleLockItem(payload: payload, modelContext: modelContext, context: context)

        case "setMood":
            handleSetMood(payload: payload, modelContext: modelContext, context: context)

        default:
            complete(context: context, response: ["ok": false, "error": "unknown_type"])
        }
    }

    private func handleLockItem(payload: [String: Any], modelContext: ModelContext, context: NSExtensionContext) {
        guard
            let name = payload["name"] as? String,
            let price = payload["price"] as? Double
        else {
            complete(context: context, response: ["ok": false, "error": "missing_fields"])
            return
        }
        let domain = payload["domain"] as? String
        let currencyCode = payload["currencyCode"] as? String ?? "TRY"
        let settings = fetchOrCreateSettings(in: modelContext)
        let targetName = name

        let existing = try? modelContext.fetch(FetchDescriptor<PurchaseItem>(
            predicate: #Predicate { $0.statusRaw == "waiting" && $0.name == targetName }
        )).first

        let isNeed = payload["isNeed"] as? Bool
        let alreadyOwnsSimilar = payload["alreadyOwnsSimilar"] as? Bool
        let trigger = (payload["trigger"] as? String).flatMap { PurchaseTrigger(rawValue: $0) }

        let target: PurchaseItem
        if let existing {
            target = existing
            target.isNeed = isNeed
            target.alreadyOwnsSimilar = alreadyOwnsSimilar
            target.trigger = trigger
        } else {
            let newItem = PurchaseItem(
                name: name,
                price: price,
                currencyCode: currencyCode,
                category: .other,
                cooldownHours: settings.defaultCooldownHours,
                source: .extensionSource,
                sourceDomain: domain,
                isNeed: isNeed,
                alreadyOwnsSimilar: alreadyOwnsSimilar,
                trigger: trigger
            )
            modelContext.insert(newItem)
            target = newItem
        }
        try? modelContext.save()
        WidgetCenter.shared.reloadAllTimelines()

        complete(context: context, response: [
            "ok": true,
            "cooldownEndsAt": target.cooldownEndsAt.timeIntervalSince1970,
            "isCooldownComplete": target.isCooldownComplete
        ])
    }

    private func handleSetMood(payload: [String: Any], modelContext: ModelContext, context: NSExtensionContext) {
        guard
            let name = payload["name"] as? String,
            let moodRaw = payload["mood"] as? String
        else {
            complete(context: context, response: ["ok": false, "error": "missing_fields"])
            return
        }
        let targetName = name
        let existing = try? modelContext.fetch(FetchDescriptor<PurchaseItem>(
            predicate: #Predicate { $0.statusRaw == "waiting" && $0.name == targetName }
        )).first
        existing?.moodRaw = moodRaw
        try? modelContext.save()
        complete(context: context, response: ["ok": true])
    }

    private func fetchOrCreateSettings(in context: ModelContext) -> UserSettings {
        if let existing = try? context.fetch(FetchDescriptor<UserSettings>()).first {
            return existing
        }
        let created = UserSettings()
        context.insert(created)
        try? context.save()
        return created
    }

    private func complete(context: NSExtensionContext, response: [String: Any]) {
        let responseItem = NSExtensionItem()
        responseItem.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }
}
