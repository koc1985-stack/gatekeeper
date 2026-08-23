import Foundation

/// Bir kerede alınmış canlı piyasa anlık görüntüsü — döviz kurları TCMB'nin resmi günlük XML
/// akışından, ons altın fiyatı ise anahtar gerektirmeyen ücretsiz bir spot fiyat servisinden gelir.
struct LiveMarketSnapshot {
    let usdTRY: Double
    let eurTRY: Double
    let goldOunceUSD: Double
    let fetchedAt: Date

    private static let gramsPerTroyOunce = 31.1034768

    /// Ons altın (USD) → gram altın (TRY). Türkiye'de "gram altın" olarak satılan 24 ayar has altına
    /// yakın bir yaklaşım; gerçek kuyumcu fiyatları küçük bir işçilik/prim farkı içerebilir.
    var gramGoldTRY: Double {
        (goldOunceUSD / Self.gramsPerTroyOunce) * usdTRY
    }
}

/// Uygulama içinde canlı veri çekebilen tek nokta: TCMB döviz kurları (USD/EUR) ve ons altın (XAU/USD)
/// spot fiyatı. Ağ isteği başarısız olursa `nil` döner — çağıran taraf her zaman statik geçmiş
/// verilere geri dönebilmelidir (bkz. TurkishInvestmentAsset), kullanıcı hiçbir zaman boş bir ekranla
/// karşılaşmamalıdır.
enum LiveMarketDataService {
    private static let tcmbURL = URL(string: "https://www.tcmb.gov.tr/kurlar/today.xml")!
    private static let goldURL = URL(string: "https://api.gold-api.com/price/XAU")!

    static func fetchSnapshot() async -> LiveMarketSnapshot? {
        async let ratesTask = fetchTCMBRates()
        async let goldTask = fetchGoldOunceUSD()
        guard let rates = await ratesTask, let gold = await goldTask else { return nil }
        return LiveMarketSnapshot(usdTRY: rates.usd, eurTRY: rates.eur, goldOunceUSD: gold, fetchedAt: .now)
    }

    private static func fetchTCMBRates() async -> (usd: Double, eur: Double)? {
        var request = URLRequest(url: tcmbURL)
        request.timeoutInterval = 8
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        let parser = TCMBRateParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        guard xmlParser.parse(), let usd = parser.rates["USD"], let eur = parser.rates["EUR"], usd > 0, eur > 0 else {
            return nil
        }
        return (usd, eur)
    }

    private static func fetchGoldOunceUSD() async -> Double? {
        var request = URLRequest(url: goldURL)
        request.timeoutInterval = 8
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        struct GoldResponse: Decodable { let price: Double }
        guard let price = try? JSONDecoder().decode(GoldResponse.self, from: data).price, price > 0 else { return nil }
        return price
    }
}

/// TCMB'nin today.xml'i için minimal bir XML ayrıştırıcı — sadece USD ve EUR'un
/// <ForexSelling> değerini okur, başka hiçbir alanla ilgilenmez.
private final class TCMBRateParser: NSObject, XMLParserDelegate {
    private(set) var rates: [String: Double] = [:]
    private var currentCode: String?
    private var currentElement = ""
    private var buffer = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        currentElement = elementName
        if elementName == "Currency" {
            currentCode = attributeDict["Kod"]
        }
        buffer = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElement == "ForexSelling" {
            buffer += string
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "ForexSelling", let code = currentCode,
           let value = Double(buffer.trimmingCharacters(in: .whitespacesAndNewlines)) {
            rates[code] = value
        }
    }
}
