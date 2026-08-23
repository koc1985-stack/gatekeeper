import SwiftUI

/// The "bir düşün" questions: need vs. want, redundancy check, what triggered the urge, how long
/// it's been on the user's mind, current mood, and anticipated regret — combined into a
/// deterministic (no AI, no network) weighted impulse-risk score plus a tailored coaching tip.
/// Reused by AddItemView and the Share Extension's AddFromShareView so the same reflection happens
/// no matter how the item was logged.
struct ReflectionSection: View {
    @Binding var isNeed: Bool?
    @Binding var alreadyOwnsSimilar: Bool?
    @Binding var trigger: PurchaseTrigger?
    @Binding var consideration: ConsiderationPeriod?
    @Binding var futureOutlook: FutureOutlook?
    let price: Double
    let monthlyIncome: Double
    let mood: Mood?

    private struct Signal {
        let text: String
        let weight: Int
        let tip: String
    }

    private var percentOfIncome: Double? {
        guard monthlyIncome > 0, price > 0 else { return nil }
        return (price / monthlyIncome) * 100
    }

    /// Ağırlıklar deneyimsel/sezgiseldir (klinik bir ölçek değildir) — amaç kesin bir teşhis değil,
    /// kullanıcıyı birkaç saniyeliğine durup düşünmeye teşvik etmektir. Sıralama önemlidir: en
    /// güçlü sinyal, aşağıdaki "kişisel öneri" kutusunda gösterilecek ipucunu belirler.
    private var signals: [Signal] {
        var items: [Signal] = []
        if futureOutlook == .regretLikely {
            items.append(Signal(
                text: "1 hafta sonra muhtemelen pişman olacağını düşünüyorsun.",
                weight: 30,
                tip: "Kendi tahminine güven: gelecekteki sen zaten pişman olacağını söylüyor. Bu genelde en güvenilir uyarı işaretidir — bir gece daha bekle."
            ))
        } else if futureOutlook == .unsure {
            items.append(Signal(
                text: "1 hafta sonra memnun olup olmayacağından emin değilsin.",
                weight: 12,
                tip: "Emin değilsen, genelde cevap hayırdır. Soğuma süresi bitince tekrar sor kendine."
            ))
        }
        if isNeed == false {
            items.append(Signal(
                text: "Bunu \"istek\" olarak işaretledin, ihtiyaç değil.",
                weight: 22,
                tip: "İhtiyaç değilse aciliyeti de yok — soğuma süresini beklemek hiçbir şey kaybettirmez."
            ))
        }
        if alreadyOwnsSimilar == true {
            items.append(Signal(
                text: "Zaten benzer bir şeyin olduğunu söyledin.",
                weight: 15,
                tip: "Elindeki benzer üründen neyin eksik olduğunu net biçimde söyleyemiyorsan, muhtemelen yenisine gerek yok."
            ))
        }
        if let percent = percentOfIncome, percent >= 5 {
            let weight = percent >= 15 ? 25 : 14
            items.append(Signal(
                text: "Bu, aylık gelirinin yaklaşık %\(Int(percent.rounded()))'i.",
                weight: weight,
                tip: "Bütçende görünür bir iz bırakan harcamalar için 24 saat kuralı özellikle işe yarar — acele etme."
            ))
        }
        if trigger == .ad || trigger == .browsing {
            items.append(Signal(
                text: "Bunu bir reklamda ya da sıkılıp gezinirken görmüşsün — bu genelde dürtüsel bir tetikleyicidir.",
                weight: 20,
                tip: "Reklam/gezinme kaynaklı istekler birkaç saat içinde büyük oranda geçer. Uygulamayı kapat, soğuma süresi bitince tekrar bak."
            ))
        }
        if consideration == .justNow {
            items.append(Signal(
                text: "Bunu az önce gördün — üzerine düşünme süren neredeyse hiç olmadı.",
                weight: 20,
                tip: "Düşünme süresi sıfıra yakınsa karar da genelde dürtüseldir. Listene ekle, yarın tekrar değerlendir."
            ))
        }
        if let mood, mood != .happy {
            items.append(Signal(
                text: "Şu an \(String(localized: mood.displayName).lowercased()) hissediyorsun — bu ruh halinde alışveriş genelde dürtüseldir.",
                weight: 15,
                tip: "Duygu durumun geçtikten sonra aynı ürünü hâlâ istiyor musun diye bir daha sor kendine."
            ))
        }
        return items
    }

    private var riskScore: Int {
        min(100, signals.reduce(0) { $0 + $1.weight })
    }

    private var dominantTip: String? {
        signals.max(by: { $0.weight < $1.weight })?.tip
    }

    private var verdictColor: Color {
        switch riskScore {
        case 0..<25: return .green
        case 25..<55: return .orange
        default: return .red
        }
    }

    private var verdictText: LocalizedStringResource {
        switch riskScore {
        case 0..<25: return "Muhtemelen bilinçli bir karar"
        case 25..<55: return "Bir kez daha düşün"
        default: return "Yüksek dürtü riski"
        }
    }

    var body: some View {
        Section {
            Picker("İhtiyaç mı, istek mi?", selection: $isNeed) {
                Text("Seçilmedi").tag(Bool?.none)
                Text("İhtiyaç").tag(Bool?.some(true))
                Text("İstek").tag(Bool?.some(false))
            }
            .pickerStyle(.segmented)

            Toggle("Zaten benzer bir şeyin var mı?", isOn: Binding(
                get: { alreadyOwnsSimilar ?? false },
                set: { alreadyOwnsSimilar = $0 }
            ))

            Picker("Bunu nereden gördün?", selection: $trigger) {
                Text("Seçilmedi").tag(PurchaseTrigger?.none)
                ForEach(PurchaseTrigger.allCases) { item in
                    Text(item.displayName).tag(PurchaseTrigger?.some(item))
                }
            }

            Picker("Bunu ne zamandır istiyorsun?", selection: $consideration) {
                Text("Seçilmedi").tag(ConsiderationPeriod?.none)
                ForEach(ConsiderationPeriod.allCases) { item in
                    Text(item.displayName).tag(ConsiderationPeriod?.some(item))
                }
            }

            Picker("1 hafta sonra bu karardan memnun olur musun?", selection: $futureOutlook) {
                Text("Seçilmedi").tag(FutureOutlook?.none)
                ForEach(FutureOutlook.allCases) { item in
                    Text(item.displayName).tag(FutureOutlook?.some(item))
                }
            }

            if !signals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Gauge(value: Double(riskScore), in: 0...100) {
                            Text("Dürtü Riski")
                        } currentValueLabel: {
                            Text("\(riskScore)")
                        }
                        .gaugeStyle(.accessoryCircularCapacity)
                        .tint(verdictColor)
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(verdictText)
                                .font(.subheadline.bold())
                                .foregroundStyle(verdictColor)
                            Text("Dürtü Riski Skoru: \(riskScore)/100")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(signals, id: \.text) { signal in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•")
                            Text(signal.text)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if let dominantTip {
                        Label {
                            Text(dominantTip)
                                .font(.caption)
                        } icon: {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                        }
                        .padding(10)
                        .background(verdictColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Bir Düşün")
        } footer: {
            Text("Bu sorular seni yargılamak için değil, anlık kararını bir kez daha gözden geçirmen için. Skor kesin bir teşhis değil, kaba bir uyarı işaretidir.")
        }
    }
}
