import Foundation
import SwiftUI
import SwiftData

private enum HistoryFilter: String, CaseIterable {
    case all
    case bought
    case skipped

    var label: LocalizedStringResource {
        switch self {
        case .all: return "Tümü"
        case .bought: return "Aldıklarım"
        case .skipped: return "Vazgeçtiklerim"
        }
    }
}

struct HistoryView: View {
    @Query(
        filter: #Predicate<PurchaseItem> { $0.statusRaw != "waiting" },
        sort: [SortDescriptor(\PurchaseItem.decidedAt, order: .reverse)]
    )
    private var decidedItems: [PurchaseItem]

    @State private var filter: HistoryFilter = .all

    private var filteredItems: [PurchaseItem] {
        switch filter {
        case .all: return decidedItems
        case .bought: return decidedItems.filter { $0.status == .bought }
        case .skipped: return decidedItems.filter { $0.status == .skipped }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filtre", selection: $filter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { item in
                        Text(item.label).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "Henüz karar yok",
                        systemImage: "tray",
                        description: Text("Bekleme süresi biten istekler burada listelenir.")
                    )
                } else {
                    List(filteredItems) { item in
                        HistoryRow(item: item)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Geçmiş")
        }
    }
}

private struct HistoryRow: View {
    let item: PurchaseItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.status == .bought ? "cart.fill" : "checkmark.seal.fill")
                .foregroundStyle(item.status == .bought ? .secondary : .green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.headline)
                if let decidedAt = item.decidedAt {
                    Text(decidedAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(CurrencyFormatter.format(item.price, currencyCode: item.currencyCode))
                .font(.subheadline.bold())
        }
        .padding(.vertical, 4)
    }
}
