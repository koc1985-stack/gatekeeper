import Foundation
import SwiftData

/// App Group identifier shared by the main app, the Safari Web Extension, and the widget —
/// all three need to read/write the same SwiftData store from separate processes.
enum AppGroup {
    static let identifier = "group.com.impulsegatekeeper.app"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group container bulunamadı — Xcode'da Signing & Capabilities altında '\(identifier)' App Group'unun tüm hedeflere eklendiğinden emin olun.")
        }
        return url
    }
}

enum SharedModelContainer {
    /// One shared SwiftData store living in the App Group container, opened identically by the
    /// app, the extension's native handler, and the widget so a purchase logged from any of them
    /// is immediately visible to the others.
    static func make() -> ModelContainer {
        let schema = Schema([PurchaseItem.self, UserSettings.self])
        let storeURL = AppGroup.containerURL.appending(path: "ImpulseGatekeeper.sqlite")
        let configuration = ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }
}
