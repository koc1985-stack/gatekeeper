import Charts
import Foundation
import SwiftUI

/// Türkiye'de yaygın yatırım araçlarının (gram/çeyrek altın, dolar, euro, BIST 100) son 10 yıllık
/// gerçek trendini, mümkün olduğunda canlı güncel değerle birleştirilmiş halde, ve bu trende dayalı
/// 5 yıllık projeksiyonunu tek bir eğri üzerinde gösterir. Premium olmayan kullanıcılar bu ekranı bir
/// kez ücretsiz görebilir (gate mantığı çağıran view'da uygulanır).
struct InvestmentAnalysisView: View {
    let itemPrice: Double
    let currencyCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAsset: TurkishInvestmentAsset = .gramGold
    @State private var liveSnapshot: LiveMarketSnapshot?
    @State private var isLoadingLiveData = true

    private var liveValue: Double? {
        guard selectedAsset.supportsLiveData, let liveSnapshot else { return nil }
        return selectedAsset.liveValue(from: liveSnapshot)
    }

    private var series: (historical: [YearValue], projected: [YearValue]) {
        selectedAsset.projectedSeries(includingLive: liveValue)
    }

    private var accentColor: Color { Self.color(for: selectedAsset) }

    private static func color(for asset: TurkishInvestmentAsset) -> Color {
        switch asset {
        case .gramGold, .quarterGold: return .yellow
        case .usd: return .green
        case .eur: return .blue
        case .bist100: return .purple
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    assetPicker
                    headerCard
                    chartSection
                    summarySection
                    Text("Değerler geçmiş yıl sonu piyasa verilerine dayalı yaklaşık rakamlardır; dolar, euro ve altın için mümkün olduğunda güncel piyasa değeri kullanılır. Gelecek tahmini, son 10 yılın ortalama yıllık değişiminin aynı şekilde devam ettiği varsayımına dayanır — yatırım tavsiyesi değildir, geçmiş performans gelecek için garanti oluşturmaz.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("Yatırım Analizi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .task {
                liveSnapshot = await LiveMarketDataService.fetchSnapshot()
                isLoadingLiveData = false
            }
        }
    }

    private var assetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TurkishInvestmentAsset.allCases) { asset in
                    let isSelected = selectedAsset == asset
                    let assetColor = Self.color(for: asset)
                    Button {
                        selectedAsset = asset
                    } label: {
                        Label {
                            Text(asset.displayName)
                        } icon: {
                            Image(systemName: asset.symbolName)
                        }
                        .font(.subheadline.weight(isSelected ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSelected ? assetColor.opacity(0.22) : Color.gray.opacity(0.12))
                        .foregroundStyle(isSelected ? assetColor : Color.primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(accentColor.opacity(0.18)).frame(width: 52, height: 52)
                Image(systemName: selectedAsset.symbolName)
                    .font(.title2)
                    .foregroundStyle(accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedAsset.displayName)
                    .font(.headline)
                liveStatusLabel
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var liveStatusLabel: some View {
        if isLoadingLiveData && selectedAsset.supportsLiveData {
            HStack(spacing: 6) {
                ProgressView().controlSize(.mini)
                Text("Güncel değer alınıyor…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else if let liveValue {
            HStack(spacing: 6) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("Canlı: \(CurrencyFormatter.format(liveValue, currencyCode: "TRY"))")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        } else {
            Text("Tahmini son değer kullanılıyor")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // Not: AreaMark bilerek kullanılmıyor. AreaMark'ın varsayılan dolgu tabanı 0'dır ve logaritmik
    // bir eksende 0 tanımsızdır (log(0) yoktur) — bu ikisinin birlikte kullanılması Swift Charts'ta
    // gerçek bir çökmeye yol açıyor. Bu yüzden sadece çizgi + nokta işaretleri kullanıyoruz.
    @ChartContentBuilder
    private var historicalMarks: some ChartContent {
        ForEach(series.historical) { point in
            LineMark(x: .value("Yıl", point.year), y: .value("Değer", point.value))
                .foregroundStyle(accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            PointMark(x: .value("Yıl", point.year), y: .value("Değer", point.value))
                .foregroundStyle(accentColor)
                .symbolSize(24)
        }
    }

    @ChartContentBuilder
    private var projectedMarks: some ChartContent {
        ForEach(series.projected) { point in
            LineMark(x: .value("Yıl", point.year), y: .value("Değer", point.value))
                .foregroundStyle(accentColor.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                .interpolationMethod(.catmullRom)
        }
    }

    @ChartContentBuilder
    private var todayRuleMark: some ChartContent {
        if let todayYear = series.historical.last?.year {
            RuleMark(x: .value("Bugün", todayYear))
                .foregroundStyle(.secondary.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Bugün")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var chartSection: some View {
        Chart {
            historicalMarks
            projectedMarks
            todayRuleMark
        }
        // Logaritmik ölçek: TRY cinsinden bu araçların 10 yıllık büyümesi kat kat (bazen 10x+)
        // olduğundan, doğrusal bir eksen erken yılları görünmez kılıp trendi tek bir sıçrama gibi
        // gösterir. Log ölçek, her yıldaki oransal değişimi de doğru şekilde okunabilir kılar.
        .chartYScale(type: .log)
        .chartLegend(.hidden)
        .frame(height: 240)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Son 10 yıl ortalama yıllık değişim")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("%\(String(format: "%.1f", selectedAsset.cagr(includingLive: liveValue) * 100))")
                        .font(.title.bold())
                        .foregroundStyle(accentColor)
                }
                Spacer()
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title)
                    .foregroundStyle(accentColor)
            }

            if itemPrice > 0 {
                Divider()
                Text("Bu ürünü almak yerine \(String(localized: selectedAsset.displayName))'a yatırsaydın, 5 yıl sonra tahmini değeri:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(
                    selectedAsset.projectedValue(of: itemPrice, afterYears: 5, includingLive: liveValue),
                    currencyCode: currencyCode
                ))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
            }
        }
        .padding(18)
        .background(accentColor.opacity(0.08))
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
