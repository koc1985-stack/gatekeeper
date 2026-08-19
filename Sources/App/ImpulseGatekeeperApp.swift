import SwiftUI
import SwiftData
import UserNotifications

@main
struct ImpulseGatekeeperApp: App {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([PurchaseItem.self, UserSettings.self])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }

        UNUserNotificationCenter.current().delegate = NotificationService.shared
        NotificationService.shared.registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
