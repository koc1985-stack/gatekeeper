import Foundation

/// A single year-end data point, used both for historical series and forward projections.
struct YearValue: Identifiable, Hashable {
    let year: Int
    let value: Double
    var id: Int { year }
}

/// Türkiye'de yaygın yatırım araçları — gram/çeyrek altın, döviz (USD/EUR) ve BIST 100.
/// Yıl sonu değerleri kamuya açık piyasa verilerine dayalı yaklaşık rakamlardır (eğitim amaçlı),
/// canlı/gerçek zamanlı veri değildir ve yatırım tavsiyesi oluşturmaz.
enum TurkishInvestmentAsset: String, CaseIterable, Identifiable, Hashable {
    case gramGold
    case quarterGold
    case usd
    case eur
    case bist100

    var id: String { rawValue }

    var displayName: LocalizedStringResource {
        switch self {
        case .gramGold: return "Gram Altın"
        case .quarterGold: return "Çeyrek Altın"
        case .usd: return "Dolar (USD)"
        case .eur: return "Euro (EUR)"
        case .bist100: return "BIST 100"
        }
    }

    var symbolName: String {
        switch self {
        case .gramGold: return "seal.fill"
        case .quarterGold: return "seal"
        case .usd: return "dollarsign.circle.fill"
        case .eur: return "eurosign.circle.fill"
        case .bist100: return "chart.line.uptrend.xyaxis"
        }
    }

    /// Yaklaşık yıl sonu değerleri (TRY). Çeyrek altın, gram altının ~1.6 katsayısıyla türetilir
    /// (çeyrek altının yaklaşık has altın içeriği + basım primi). BIST 100 değerleri, Temmuz 2020'deki
    /// endeks yeniden ölçeklendirmesiyle (÷100) tutarlı olacak şekilde 2020 öncesi için ayarlanmıştır.
    var historicalYearEndValues: [YearValue] {
        switch self {
        case .gramGold:
            return Self.points([
                (2016, 144), (2017, 153), (2018, 228), (2019, 267), (2020, 444),
                (2021, 747), (2022, 1177), (2023, 1980), (2024, 2900), (2025, 4400),
            ])
        case .quarterGold:
            return TurkishInvestmentAsset.gramGold.historicalYearEndValues.map {
                YearValue(year: $0.year, value: $0.value * 1.6)
            }
        case .usd:
            return Self.points([
                (2016, 3.53), (2017, 3.79), (2018, 5.32), (2019, 5.95), (2020, 7.43),
                (2021, 13.30), (2022, 18.70), (2023, 29.50), (2024, 35.30), (2025, 42.00),
            ])
        case .eur:
            return Self.points([
                (2016, 3.71), (2017, 4.55), (2018, 6.08), (2019, 6.68), (2020, 9.13),
                (2021, 15.09), (2022, 19.96), (2023, 32.60), (2024, 36.70), (2025, 44.50),
            ])
        case .bist100:
            return Self.points([
                (2016, 781), (2017, 1153), (2018, 913), (2019, 1144), (2020, 1477),
                (2021, 1857), (2022, 5509), (2023, 7491), (2024, 9800), (2025, 10800),
            ])
        }
    }

    private static func points(_ raw: [(Int, Double)]) -> [YearValue] {
        raw.map { YearValue(year: $0.0, value: $0.1) }
    }

    /// Geçmiş serinin ilk ve son noktasından türetilen bileşik yıllık büyüme oranı (CAGR).
    var cagr: Double {
        let series = historicalYearEndValues
        guard let first = series.first, let last = series.last, first.value > 0 else { return 0 }
        let years = Double(last.year - first.year)
        guard years > 0 else { return 0 }
        return pow(last.value / first.value, 1 / years) - 1
    }

    /// Geçmiş veriyi ve bu geçmiş CAGR'a göre `forwardYears` kadar ileriye uzatılmış tahmini birlikte döner.
    /// Tahmin noktaları grafikte kesikli çizgiyle ayrıştırılmak üzere ayrı bir dizi olarak verilir.
    func projectedSeries(forwardYears: Int = 5) -> (historical: [YearValue], projected: [YearValue]) {
        let historical = historicalYearEndValues
        guard let last = historical.last else { return (historical, []) }
        let rate = cagr
        var projected: [YearValue] = [last]
        for step in 1...forwardYears {
            projected.append(YearValue(year: last.year + step, value: last.value * pow(1 + rate, Double(step))))
        }
        return (historical, projected)
    }

    /// `amount` tutarının, bu aracın geçmiş CAGR'ı ile `years` yıl sonra tahmini değeri.
    func projectedValue(of amount: Double, afterYears years: Double) -> Double {
        WageCalculator.projectedValue(principal: amount, years: years, annualRate: cagr)
    }
}
