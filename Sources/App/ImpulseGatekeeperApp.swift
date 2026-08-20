import SwiftUI
import SwiftData
import UserNotifications

@main
struct ImpulseGatekeeperApp: App {
    let modelContainer: ModelContainer

    init() {
        modelContainer = SharedModelContainer.make()

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
