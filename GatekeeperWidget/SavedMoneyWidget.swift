import WidgetKit
import SwiftUI
import SwiftData

struct SavedMoneyEntry: TimelineEntry {
    let date: Date
    let totalSaved: Double
    let totalHoursSaved: Double
    let currencyCode: String
}

struct SavedMoneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SavedMoneyEntry {
        SavedMoneyEntry(date: .now, totalSaved: 14200, totalHoursSaved: 62, currencyCode: "TRY")
    }

    func getSnapshot(in context: Context, completion: @escaping (SavedMoneyEntry) -> Void) {
        completion(computeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SavedMoneyEntry>) -> Void) {
        let entry = computeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: .now) ?? entry.date.addingTimeInterval(4 * 3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func computeEntry() -> SavedMoneyEntry {
        let container = SharedModelContainer.make()
        let context = ModelContext(container)
        let calendar = Calendar.current
        let now = Date.now
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

        let skippedDescriptor = FetchDescriptor<PurchaseItem>(predicate: #Predicate<PurchaseItem> { $0.statusRaw == "skipped" })
        let skippedItems = (try? context.fetch(skippedDescriptor)) ?? []
        let thisMonth = skippedItems.filter { item in
            guard let decidedAt = item.decidedAt else { return false }
            return decidedAt >= startOfMonth
        }

        let settings = (try? context.fetch(FetchDescriptor<UserSettings>()))?.first
        let hourlyWage = settings?.effectiveHourlyWage ?? 0
        let currencyCode = settings?.currencyCode ?? "TRY"

        let totalSaved = thisMonth.reduce(0) { $0 + $1.price }
        let totalHours = thisMonth.reduce(0.0) { $0 + WageCalculator.hoursRequired(price: $1.price, hourlyWage: hourlyWage) }

        return SavedMoneyEntry(date: .now, totalSaved: totalSaved, totalHoursSaved: totalHours, currencyCode: currencyCode)
    }
}

struct SavedMoneyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SavedMoneyEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("Bu Ay Kurtarılan")
                    .font(.caption2)
                Text(CurrencyFormatter.format(entry.totalSaved, currencyCode: entry.currencyCode))
                    .font(.headline.bold())
            }
        case .accessoryInline:
            Text("Kurtarılan: \(CurrencyFormatter.format(entry.totalSaved, currencyCode: entry.currencyCode))")
        case .systemMedium:
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bu Ay Kurtarılan")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(CurrencyFormatter.format(entry.totalSaved, currencyCode: entry.currencyCode))
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Kazandığın Zaman")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(WageCalculator.formattedHours(entry.totalHoursSaved))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding()
        default:
            VStack(spacing: 4) {
                Text("Bu Ay Kurtarılan")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                Text(CurrencyFormatter.format(entry.totalSaved, currencyCode: entry.currencyCode))
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
            }
            .padding()
        }
    }
}

struct SavedMoneyWidget: Widget {
    let kind = "SavedMoneyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SavedMoneyProvider()) { entry in
            SavedMoneyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
        }
        .configurationDisplayName("Kurtarılan Para")
        .description("Bu ay dürtüsel alışverişten kurtardığın parayı gösterir.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}
