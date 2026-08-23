import Charts
import Foundation
import SwiftUI

/// Türkiye'de yaygın yatırım araçlarının (gram/çeyrek altın, dolar, euro, BIST 100) son 10 yıllık
/// gerçek trendini ve bu trende dayalı 5 yıllık projeksiyonunu gösterir. Premium olmayan kullanıcılar
/// bu ekranı bir kez ücretsiz görebilir (gate mantığı çağıran view'da uygulanır).
struct InvestmentAnalysisView: View {
    let itemPrice: Double
    let currencyCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedAsset: TurkishInvestmentAsset = .gramGold

    private var series: (historical: [YearValue], projected: [YearValue]) {
        selectedAsset.projectedSeries()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    assetPicker

                    chartSection

                    summarySection

                    Text("Değerler, geçmiş yıl sonu piyasa verilerine dayalı yaklaşık rakamlardır. Gelecek tahmini, son 10 yılın ortalama yıllık değişiminin aynı şekilde devam ettiği varsayımına dayanır — yatırım tavsiyesi değildir, geçmiş performans gelecek için garanti oluşturmaz.")
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
        }
    }

    private var assetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TurkishInvestmentAsset.allCases) { asset in
                    Button {
                        selectedAsset = asset
                    } label: {
                        Label {
                            Text(asset.displayName)
                        } icon: {
                            Image(systemName: asset.symbolName)
                        }
                        .font(.subheadline.weight(selectedAsset == asset ? .semibold : .regular))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedAsset == asset ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12))
                        .foregroundStyle(selectedAsset == asset ? Color.accentColor : Color.primary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var chartSection: some View {
        Chart {
            ForEach(series.historical) { point in
                LineMark(x: .value("Yıl", point.year), y: .value("Değer", point.value))
                    .foregroundStyle(by: .value("Tip", "Geçmiş (10 yıl)"))
                    .interpolationMethod(.catmullRom)
            }
            ForEach(series.projected) { point in
                LineMark(x: .value("Yıl", point.year), y: .value("Değer", point.value))
                    .foregroundStyle(by: .value("Tip", "Tahmin (5 yıl)"))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
        }
        .chartForegroundStyleScale([
            "Geçmiş (10 yıl)": Color.blue,
            "Tahmin (5 yıl)": Color.orange,
        ])
        .chartLegend(position: .bottom)
        .frame(height: 220)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("Son 10 yıl ortalama yıllık değişim: %\(String(format: "%.1f", selectedAsset.cagr * 100))")
                    .font(.subheadline.bold())
            } icon: {
                Image(systemName: selectedAsset.symbolName)
                    .foregroundStyle(.yellow)
            }

            if itemPrice > 0 {
                Divider()
                Text("Bu ürünü almak yerine \(String(localized: selectedAsset.displayName))'a yatırsaydın, 5 yıl sonra tahmini değeri:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(CurrencyFormatter.format(
                    selectedAsset.projectedValue(of: itemPrice, afterYears: 5),
                    currencyCode: currencyCode
                ))
                .font(.title2.bold())
                .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
