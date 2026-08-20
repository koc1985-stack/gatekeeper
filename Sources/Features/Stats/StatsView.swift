import SwiftUI
import SwiftData
import UIKit
import Charts

private struct MoodStat: Identifiable {
    let mood: Mood
    let total: Double
    var id: String { mood.rawValue }
}

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

    private var moodStats: [MoodStat] {
        let grouped = Dictionary(grouping: skippedItems.compactMap { item -> (Mood, Double)? in
            guard let mood = item.mood else { return nil }
            return (mood, item.price)
        }, by: { $0.0 })
        return Mood.allCases.compactMap { mood in
            guard let entries = grouped[mood], !entries.isEmpty else { return nil }
            return MoodStat(mood: mood, total: entries.reduce(0) { $0 + $1.1 })
        }
    }

    private var shareCardContent: ShareCardView {
        ShareCardView(saved: totalSaved, hours: totalHoursSaved, currencyCode: currencyCode)
    }

    private var shareImage: Image {
        let renderer = ImageRenderer(content: shareCardContent)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "square.and.arrow.up")
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

                    if !moodStats.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hangi ruh halinde vazgeçtin?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Chart(moodStats) { stat in
                                BarMark(
                                    x: .value("Tutar", stat.total),
                                    y: .value("Ruh Hali", stat.mood.emoji)
                                )
                                .foregroundStyle(.orange.gradient)
                            }
                            .frame(height: CGFloat(moodStats.count) * 44 + 20)
                        }
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

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

                        if InstagramShareService.isInstagramAvailable {
                            Button {
                                shareToInstagram()
                            } label: {
                                Label("Instagram'da Paylaş", systemImage: "camera.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("İstatistikler")
        }
    }

    private func shareToInstagram() {
        let renderer = ImageRenderer(content: shareCardContent)
        renderer.scale = 3
        guard let uiImage = renderer.uiImage else { return }
        InstagramShareService.shareToStory(backgroundImage: uiImage)
    }
}
