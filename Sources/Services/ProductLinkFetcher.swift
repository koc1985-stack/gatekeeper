import Foundation

/// Best-effort product info extraction from a pasted URL: fetches the page's raw HTML and reads
/// whatever a site already publishes for link previews/SEO (Open Graph tags, schema.org JSON-LD
/// Product markup) — no JavaScript execution, so sites that only render price client-side won't
/// yield one. Callers must treat every field as optional and let the user fill in the rest;
/// this could not be verified against real Trendyol/Amazon/Zara/H&M responses in this environment.
enum ProductLinkFetcher {
    struct ProductInfo {
        var name: String?
        var price: Double?
        var currencyCode: String?
        var imageURL: URL?
    }

    static func fetch(from url: URL) async -> ProductInfo? {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 10

        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            return nil
        }

        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
        guard let html else { return nil }

        var info = ProductInfo()
        info.name = metaContent(in: html, key: "og:title") ?? pageTitle(in: html)
        if let imageString = metaContent(in: html, key: "og:image"), let imageURL = URL(string: imageString) {
            info.imageURL = imageURL
        }

        if let priceString = metaContent(in: html, key: "product:price:amount")
            ?? metaContent(in: html, key: "og:price:amount") {
            info.price = parsePrice(priceString)
        }
        info.currencyCode = metaContent(in: html, key: "product:price:currency")
            ?? metaContent(in: html, key: "og:price:currency")

        if info.price == nil, let jsonLD = jsonLDPrice(in: html) {
            info.price = jsonLD.price
            info.currencyCode = info.currencyCode ?? jsonLD.currencyCode
        }

        return info
    }

    // MARK: - Open Graph / meta tags

    private static func metaContent(in html: String, key: String) -> String? {
        let escapedKey = NSRegularExpression.escapedPattern(for: key)
        let patterns = [
            "<meta[^>]*(?:property|name)=[\"']\(escapedKey)[\"'][^>]*content=[\"']([^\"']*)[\"']",
            "<meta[^>]*content=[\"']([^\"']*)[\"'][^>]*(?:property|name)=[\"']\(escapedKey)[\"']"
        ]
        for pattern in patterns {
            if let value = firstMatch(pattern: pattern, in: html, group: 1) {
                return value.removingPercentEncoding ?? value
            }
        }
        return nil
    }

    private static func pageTitle(in html: String) -> String? {
        firstMatch(pattern: "<title[^>]*>(.*?)</title>", in: html, group: 1, dotMatchesNewlines: true)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - schema.org Product JSON-LD

    private static func jsonLDPrice(in html: String) -> (price: Double, currencyCode: String?)? {
        guard let regex = try? NSRegularExpression(
            pattern: "<script[^>]*type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }

        let fullRange = NSRange(html.startIndex..., in: html)
        for match in regex.matches(in: html, range: fullRange) {
            guard let range = Range(match.range(at: 1), in: html) else { continue }
            guard let data = String(html[range]).data(using: .utf8) else { continue }
            guard let json = try? JSONSerialization.jsonObject(with: data) else { continue }
            if let found = extractOffer(from: json) { return found }
        }
        return nil
    }

    private static func extractOffer(from json: Any) -> (price: Double, currencyCode: String?)? {
        if let dict = json as? [String: Any] {
            if let offer = dict["offers"] as? [String: Any], let found = priceFromOffer(offer) {
                return found
            }
            if let offers = dict["offers"] as? [[String: Any]] {
                for offer in offers {
                    if let found = priceFromOffer(offer) { return found }
                }
            }
            for (_, value) in dict {
                if let found = extractOffer(from: value) { return found }
            }
        } else if let array = json as? [Any] {
            for item in array {
                if let found = extractOffer(from: item) { return found }
            }
        }
        return nil
    }

    private static func priceFromOffer(_ offer: [String: Any]) -> (price: Double, currencyCode: String?)? {
        let rawPrice = offer["price"] ?? offer["lowPrice"]
        let price: Double?
        if let number = rawPrice as? Double {
            price = number
        } else if let number = rawPrice as? Int {
            price = Double(number)
        } else if let string = rawPrice as? String {
            price = parsePrice(string)
        } else {
            price = nil
        }
        guard let price, price > 0 else { return nil }
        return (price, offer["priceCurrency"] as? String)
    }

    // MARK: - Helpers

    private static func parsePrice(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }

    private static func firstMatch(pattern: String, in text: String, group: Int, dotMatchesNewlines: Bool = false) -> String? {
        var options: NSRegularExpression.Options = [.caseInsensitive]
        if dotMatchesNewlines { options.insert(.dotMatchesLineSeparators) }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let fullRange = NSRange(text.startIndex..., in: text)
        guard
            let match = regex.firstMatch(in: text, range: fullRange),
            let range = Range(match.range(at: group), in: text)
        else { return nil }
        return String(text[range])
    }
}
