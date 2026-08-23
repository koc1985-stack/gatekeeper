import Foundation

/// A single year-end data point, used both for historical series and forward projections.
struct YearValue: Identifiable, Hashable {
    let year: Int
    let value: Double
    var id: Int { year }
}

/// A single forward-projected year, carrying a central (most likely) estimate plus an
/// optimistic/pessimistic band derived from the asset's own historical volatility — shown as a
/// shaded "confidence cone" instead of one falsely-precise line.
struct ProjectedYearValue: Identifiable, Hashable {
    let year: Int
    let expected: Double
    let optimistic: Double
    let pessimistic: Double
    var id: Int { year }
}

/// Türkiye'de yaygın yatırım araçları — gram/çeyrek altın, döviz (USD/EUR) ve BIST 100.
/// Yıl sonu değerleri kamuya açık piyasa verilerine dayalı yaklaşık rakamlardır (eğitim amaçlı).
/// USD, EUR ve altın için en güncel nokta, mümkün olduğunda `LiveMarketDataService`'ten gelen
/// gerçek zamanlı veriyle değiştirilir (bkz. `liveValue(from:)` ve `series(includingLive:)`) —
/// BIST 100 için ücretsiz/güvenilir bir canlı kaynak bulunmadığından statik tahminde kalır.
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

    /// Bu asset'in `LiveMarketDataService.fetchSnapshot()` üzerinden canlı veri alıp alamayacağı.
    var supportsLiveData: Bool { self != .bist100 }

    /// Bir canlı piyasa anlık görüntüsünden bu aracın "şimdi" değerini türetir (varsa).
    func liveValue(from snapshot: LiveMarketSnapshot) -> Double? {
        switch self {
        case .usd: return snapshot.usdTRY
        case .eur: return snapshot.eurTRY
        case .gramGold: return snapshot.gramGoldTRY
        case .quarterGold: return snapshot.gramGoldTRY * 1.6
        case .bist100: return nil
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

    /// Statik geçmiş seriyi, varsa canlı "şimdi" değeriyle uzatır/günceller — bugünün gerçek yılı
    /// serinin son statik yılından ilerideyse yeni bir nokta eklenir, aynı yılsa üzerine yazılır.
    /// Bu sayede CAGR hesabı gerçek, en güncel veriye dayanır; statik tahmine değil.
    func series(includingLive liveValue: Double? = nil, asOf year: Int = Calendar.current.component(.year, from: .now)) -> [YearValue] {
        var points = historicalYearEndValues
        guard let liveValue, liveValue > 0, let lastYear = points.last?.year, year >= lastYear else {
            return points
        }
        if year == lastYear {
            points[points.count - 1] = YearValue(year: year, value: liveValue)
        } else {
            points.append(YearValue(year: year, value: liveValue))
        }
        return points
    }

    /// Serinin ilk ve son noktasından türetilen bileşik yıllık büyüme oranı (CAGR).
    func cagr(includingLive liveValue: Double? = nil) -> Double {
        let series = series(includingLive: liveValue)
        guard let first = series.first, let last = series.last, first.value > 0 else { return 0 }
        let years = Double(last.year - first.year)
        guard years > 0 else { return 0 }
        return pow(last.value / first.value, 1 / years) - 1
    }

    /// Bu varlığın son 10 yılındaki yıldan yıla değişim oranlarının örneklem standart sapması —
    /// tahmin bandının genişliğini (belirsizliği) buradan türetiyoruz.
    private func yearOverYearVolatility(includingLive liveValue: Double? = nil) -> Double {
        let points = series(includingLive: liveValue)
        guard points.count > 2 else { return 0 }
        let rates = zip(points, points.dropFirst()).map { $1.value / $0.value - 1 }
        let mean = rates.reduce(0, +) / Double(rates.count)
        let variance = rates.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(rates.count - 1)
        return variance.squareRoot()
    }

    /// Uzun vadede bu tür TRY cinsi varlıkların (döviz kaynaklı devalüasyon + emtia/hisse getirisi)
    /// makul sayılabilecek "durağan durum" büyüme varsayımı. Son 10 yılın aşırı yüksek CAGR'ı
    /// (ör. %40+) hiçbir zaman değişmeden 5 yıl daha sürecekmiş gibi düz bir çizgiyle uzatmak yerine,
    /// bu değere doğru kademeli olarak yavaşlatıyoruz.
    private static let steadyStateRate = 0.20
    /// Her adımda geçmiş CAGR ile durağan durum arasındaki farkın ne kadarının "eridiğini" belirler.
    private static let dampingFactor = 0.72

    /// Geçmiş (canlı veriyle güncellenmiş) veriyi ve "sönümlenen trend" (damped trend) yöntemiyle
    /// hesaplanan `forwardYears` kadar ileriye dönük tahmini — merkezi tahmin + olası aralıkla (fan
    /// chart) birlikte — döner. Sabit bir oranı olduğu gibi uzatmak yerine, her adımda büyüme oranı
    /// kademeli olarak `steadyStateRate`'e yaklaşır; bu hem grafikte gerçekçi bir eğri oluşturur hem
    /// de aşırı yüksek/düşük geçmiş oranların sonsuza dek süreceği gibi kaba bir varsayımdan kaçınır.
    func projectedSeries(includingLive liveValue: Double? = nil, forwardYears: Int = 5) -> (historical: [YearValue], projected: [ProjectedYearValue]) {
        let historical = series(includingLive: liveValue)
        guard let last = historical.last else { return (historical, []) }

        let baseRate = cagr(includingLive: liveValue)
        let volatility = yearOverYearVolatility(includingLive: liveValue)

        var expected = last.value
        var optimistic = last.value
        var pessimistic = last.value
        var projected: [ProjectedYearValue] = []

        for step in 1...forwardYears {
            let decay = pow(Self.dampingFactor, Double(step))
            let rate = Self.steadyStateRate + (baseRate - Self.steadyStateRate) * decay
            let band = volatility * decay * 0.5

            expected *= (1 + rate)
            optimistic *= (1 + max(rate + band, -0.9))
            pessimistic *= (1 + max(rate - band, -0.9))

            projected.append(ProjectedYearValue(
                year: last.year + step,
                expected: expected,
                optimistic: max(optimistic, expected),
                pessimistic: min(max(pessimistic, 0.01), expected)
            ))
        }

        return (historical, projected)
    }

    /// `amount` tutarının, sönümlenen trend yöntemiyle `years` yıl sonra tahmini (merkezi) değeri —
    /// grafikte gösterilen "beklenen" çizgiyle aynı yöntemi kullanır.
    func projectedValue(of amount: Double, afterYears years: Int, includingLive liveValue: Double? = nil) -> Double {
        guard years > 0 else { return amount }
        let baseRate = cagr(includingLive: liveValue)
        var value = amount
        for step in 1...years {
            let decay = pow(Self.dampingFactor, Double(step))
            let rate = Self.steadyStateRate + (baseRate - Self.steadyStateRate) * decay
            value *= (1 + rate)
        }
        return value
    }
}
