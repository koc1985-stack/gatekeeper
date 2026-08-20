import Foundation
import SwiftData

/// App Group identifier shared by the main app, the Safari Web Extension, and the widget —
/// all three need to read/write the same SwiftData store from separate processes.
enum AppGroup {
    static let identifier = "group.com.impulsegatekeeper.app"

    /// nil when the App Group entitlement isn't actually provisioned on this install (common
    /// with some sideloading setups, where App Group container registration can silently fail).
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

enum SharedModelContainer {
    /// One shared SwiftData store living in the App Group container, opened identically by the
    /// app, the extension's native handler, and the widget so a purchase logged from any of them
    /// is immediately visible to the others.
    ///
    /// Degrades step by step instead of crashing if a capability isn't actually provisioned on
    /// this install (App Group and/or iCloud/CloudKit — both are easy to get wrong outside of a
    /// real Xcode + paid Developer Program signing flow, e.g. some sideloading setups): App Group
    /// store with CloudKit -> App Group store without CloudKit -> local store with CloudKit ->
    /// plain local store. The app always launches; only sync/cross-process sharing is lost.
    static func make() -> ModelContainer {
        let schema = Schema([PurchaseItem.self, UserSettings.self])

        if let groupURL = AppGroup.containerURL {
            let storeURL = groupURL.appending(path: "ImpulseGatekeeper.sqlite")
            if let container = try? ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .automatic)]
            ) {
                return container
            }
            if let container = try? ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, url: storeURL)]
            ) {
                return container
            }
        }

        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
        ) {
            return container
        }

        do {
            return try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema)])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }
}
