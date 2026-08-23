import GoogleSignIn
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

        AdsSupport.startMobileAds()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    AdsSupport.requestTrackingPermissionIfNeeded()
                }
                // Google's OAuth flow reopens the app via a custom URL scheme
                // (CFBundleURLSchemes in project.yml) when sign-in completes.
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(modelContainer)
    }
}
