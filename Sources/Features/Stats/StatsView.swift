import SwiftUI
import SwiftData
import UIKit

struct StatsView: View {
    @Query(filter: #Predicate<PurchaseItem> { $0.statusRaw == "skipped" })
    private var skippedItems: [PurchaseItem]
    @Query(filter: #Predicate<PurchaseItem> { $0.statusRaw == "bought" })
    private var boughtItems: [PurchaseItem]
    @Query private var settingsList: [UserSettings]

    private var settings: UserSettings? { settingsList.first }
    private var currencyCode: String { settings?.currencyCode ?? "TRY" }

    private var totalSaved: Double {
        skippedItems.reduce(0) { $0 + $1.price }
    }

    private var totalHoursSaved: Double {
        let wage = settings?.effectiveHourlyWage ?? 0
        return skippedItems.reduce(0) { $0 + WageCalculator.hoursRequired(price: $1.price, hourlyWage: wage) }
    }

    private var skipRate: Double {
        let total = skippedItems.count + boughtItems.count
        guard total > 0 else { return 0 }
        return Double(skippedItems.count) / Double(total)
    }

    private var shareCardContent: ShareCardView {
        ShareCardView(saved: totalSaved, hours: totalHoursSaved, currencyCode: currencyCode)
    }

    private var shareImage: Image {
        let renderer = ImageRenderer(content: shareCardContent)
        renderer.scale = 3
        return renderer.image ?? Image(systemName: "square.and.arrow.up")
    }

    /// ShareLink needs a Transferable item; a PNG file URL is the most reliable way to
    /// share a rendered SwiftUI view (Messages/Photos recognize it as an actual image).
    private var shareCardFileURL: URL? {
        let renderer = ImageRenderer(content: shareCardContent)
        renderer.scale = 3
        guard let data = renderer.uiImage?.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("istatistik-karti.png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StatCard(
                        title: "Biriktirdiğin Para",
                        value: CurrencyFormatter.format(totalSaved, currencyCode: currencyCode),
                        icon: "banknote.fill",
                        tint: .green
                    )
                    StatCard(
                        title: "Kazandığın Zaman",
                        value: WageCalculator.formattedHours(totalHoursSaved),
                        icon: "clock.fill",
                        tint: .blue
                    )
                    StatCard(
                        title: "Vazgeçme Oranı",
                        value: "%\(Int((skipRate * 100).rounded()))",
                        icon: "chart.pie.fill",
                        tint: .orange
                    )

                    if !skippedItems.isEmpty, let shareCardFileURL {
                        ShareLink(
                            item: shareCardFileURL,
                            preview: SharePreview("İstatistiklerim", image: shareImage)
                        ) {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .navigationTitle("İstatistikler")
        }
    }
}
