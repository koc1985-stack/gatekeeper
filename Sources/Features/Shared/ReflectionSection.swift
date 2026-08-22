import SwiftUI

/// The "bir düşün" questions: need vs. want, redundancy check, and what actually triggered the
/// urge — plus a small deterministic (no AI, no network) analysis combining the answers with how
/// much of the user's monthly income this purchase represents. Reused by AddItemView and the
/// Share Extension's AddFromShareView so the same reflection happens no matter how the item was logged.
struct ReflectionSection: View {
    @Binding var isNeed: Bool?
    @Binding var alreadyOwnsSimilar: Bool?
    @Binding var trigger: PurchaseTrigger?
    let price: Double
    let monthlyIncome: Double

    private var percentOfIncome: Double? {
        guard monthlyIncome > 0, price > 0 else { return nil }
        return (price / monthlyIncome) * 100
    }

    private var insights: [String] {
        var lines: [String] = []
        if isNeed == false {
            lines.append("Bunu \"istek\" olarak işaretledin, ihtiyaç değil.")
        }
        if alreadyOwnsSimilar == true {
            lines.append("Zaten benzer bir şeyin olduğunu söyledin.")
        }
        if let percent = percentOfIncome, percent >= 5 {
            lines.append("Bu, aylık gelirinin yaklaşık %\(Int(percent.rounded()))'i.")
        }
        if trigger == .ad || trigger == .browsing {
            lines.append("Bunu bir reklamda ya da sıkılıp gezinirken görmüşsün — bu genelde dürtüsel bir tetikleyicidir.")
        }
        return lines
    }

    private var verdictColor: Color {
        switch insights.count {
        case 0: return .green
        case 1: return .orange
        default: return .red
        }
    }

    private var verdictText: LocalizedStringResource {
        switch insights.count {
        case 0: return "Muhtemelen bilinçli bir karar"
        case 1: return "Bir kez daha düşün"
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

            if !insights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text(verdictText)
                    } icon: {
                        Image(systemName: insights.count > 1 ? "exclamationmark.triangle.fill" : "lightbulb.fill")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(verdictColor)

                    ForEach(insights, id: \.self) { line in
                        Text("• \(line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Bir Düşün")
        } footer: {
            Text("Bu sorular seni yargılamak için değil, anlık kararını bir kez daha gözden geçirmen için.")
        }
    }
}
