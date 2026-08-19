import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<PurchaseItem> { $0.statusRaw == "waiting" }, sort: \PurchaseItem.cooldownEndsAt)
    private var waitingItems: [PurchaseItem]
    @Query private var settingsList: [UserSettings]

    @State private var storeService = StoreService.shared
    @State private var showingAddItem = false
    @State private var showingPaywall = false
    @State private var now = Date.now

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let freeItemLimit = 3

    private var settings: UserSettings? { settingsList.first }

    var body: some View {
        NavigationStack {
            Group {
                if waitingItems.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(waitingItems) { item in
                            NavigationLink(value: item.id) {
                                ItemRowView(item: item, hourlyWage: settings?.effectiveHourlyWage ?? 0, now: now)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("Bekleme Listesi")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        attemptAdd()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let item = waitingItems.first(where: { $0.id == id }) {
                    DecisionView(item: item)
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddItemView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onReceive(timer) { now = $0 }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Henüz bir istek yok", systemImage: "cart")
        } description: {
            Text("Almak istediğin bir şey mi var? Ekle ve dürtüyü geçir.")
        } actions: {
            Button("İstek Ekle") { attemptAdd() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func attemptAdd() {
        if waitingItems.count >= freeItemLimit && !storeService.isPremium {
            showingPaywall = true
        } else {
            showingAddItem = true
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = waitingItems[index]
            NotificationService.shared.cancelReminder(for: item)
            modelContext.delete(item)
        }
    }
}
