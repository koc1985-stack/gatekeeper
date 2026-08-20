import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settingsList: [UserSettings]
    @State private var notificationService = NotificationService.shared
    @State private var decisionTarget: DecisionTarget?

    private var settings: UserSettings {
        if let existing = settingsList.first { return existing }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        Group {
            if settings.hasCompletedOnboarding {
                TabView {
                    HomeView()
                        .tabItem { Label("Ana Sayfa", systemImage: "house.fill") }
                    HistoryView()
                        .tabItem { Label("Geçmiş", systemImage: "clock.arrow.circlepath") }
                    StatsView()
                        .tabItem { Label("İstatistik", systemImage: "chart.bar.fill") }
                    SettingsView()
                        .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
                }
            } else {
                OnboardingContainerView()
            }
        }
        .sheet(item: $decisionTarget) { target in
            NavigationStack {
                DecisionSheetLoader(itemID: target.id)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Kapat") { decisionTarget = nil }
                        }
                    }
            }
        }
        .onChange(of: notificationService.pendingDeepLinkItemID) { _, newValue in
            guard let id = newValue else { return }
            decisionTarget = DecisionTarget(id: id)
            notificationService.pendingDeepLinkItemID = nil
        }
        .onChange(of: notificationService.pendingQuickAction) { _, newValue in
            guard let action = newValue else { return }
            applyQuickAction(action)
            notificationService.pendingQuickAction = nil
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { reconcileNotifications() }
        }
        .task {
            reconcileNotifications()
        }
    }

    private func applyQuickAction(_ action: QuickAction) {
        let targetID = action.itemID
        let descriptor = FetchDescriptor<PurchaseItem>(predicate: #Predicate { $0.id == targetID })
        guard let item = try? modelContext.fetch(descriptor).first else { return }
        item.status = action.bought ? .bought : .skipped
        item.decidedAt = .now
    }

    /// The Safari extension can insert new "waiting" items into the shared store without being
    /// able to schedule a local notification itself (no reliable permission/UI from a headless
    /// extension process). Re-scheduling here on every foreground is idempotent — same
    /// identifier just replaces the pending request — so it also self-heals any item added while
    /// the app was killed.
    private func reconcileNotifications() {
        let descriptor = FetchDescriptor<PurchaseItem>(predicate: #Predicate<PurchaseItem> { $0.statusRaw == "waiting" })
        guard let waitingItems = try? modelContext.fetch(descriptor) else { return }
        for item in waitingItems {
            NotificationService.shared.scheduleReminder(for: item)
        }
    }
}

private struct DecisionTarget: Identifiable {
    let id: UUID
}

private struct DecisionSheetLoader: View {
    let itemID: UUID
    @Environment(\.modelContext) private var modelContext
    @State private var item: PurchaseItem?

    var body: some View {
        Group {
            if let item {
                DecisionView(item: item)
            } else {
                ProgressView()
                    .onAppear(perform: load)
            }
        }
    }

    private func load() {
        let targetID = itemID
        let descriptor = FetchDescriptor<PurchaseItem>(predicate: #Predicate { $0.id == targetID })
        item = try? modelContext.fetch(descriptor).first
    }
}
