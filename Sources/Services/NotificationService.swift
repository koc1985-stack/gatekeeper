import Foundation
import UserNotifications

struct QuickAction: Equatable {
    let itemID: UUID
    let bought: Bool
}

/// Schedules and reacts to the 24-hour cooldown reminder, including the
/// "Aldım" / "Vazgeçtim" actions a user can trigger straight from the notification.
@Observable
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private static let categoryID = "ITEM_DECISION"
    private static let boughtActionID = "ACTION_BOUGHT"
    private static let skippedActionID = "ACTION_SKIPPED"

    /// Set when the user taps the notification body (not a quick action) — the app should open the decision screen for this item.
    var pendingDeepLinkItemID: UUID?
    /// Set when the user taps "Aldım"/"Vazgeçtim" directly on the notification.
    var pendingQuickAction: QuickAction?

    private override init() {
        super.init()
    }

    func registerCategories() {
        let bought = UNNotificationAction(
            identifier: Self.boughtActionID,
            title: String(localized: "Aldım"),
            options: [.foreground]
        )
        let skipped = UNNotificationAction(
            identifier: Self.skippedActionID,
            title: String(localized: "Vazgeçtim"),
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [skipped, bought],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func scheduleReminder(for item: PurchaseItem) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Karar zamanı geldi")
        content.body = String(localized: "\(item.name) hâlâ aklında mı? Şimdi karar ver.")
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["itemID": item.id.uuidString]

        let interval = max(1, item.cooldownEndsAt.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for item: PurchaseItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard let itemID = UUID(uuidString: response.notification.request.identifier) else {
            completionHandler()
            return
        }
        switch response.actionIdentifier {
        case Self.boughtActionID:
            pendingQuickAction = QuickAction(itemID: itemID, bought: true)
        case Self.skippedActionID:
            pendingQuickAction = QuickAction(itemID: itemID, bought: false)
        default:
            pendingDeepLinkItemID = itemID
        }
        completionHandler()
    }
}
