import SwiftUI

struct ItemRowView: View {
    let item: PurchaseItem
    let hourlyWage: Double
    let now: Date

    private var progress: Double {
        let total = item.cooldownEndsAt.timeIntervalSince(item.createdAt)
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(item.createdAt)
        return min(1, max(0, elapsed / total))
    }

    private var isReady: Bool { item.cooldownEndsAt <= now }
    private var hours: Double { WageCalculator.hoursRequired(price: item.price, hourlyWage: hourlyWage) }

    var body: some View {
        HStack(spacing: 12) {
            CountdownRingView(progress: progress, isReady: isReady)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(CurrencyFormatter.format(item.price, currencyCode: item.currencyCode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if hourlyWage > 0 {
                    Text(WageCalculator.formattedHours(hours))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            if isReady {
                Text("Hazır")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Capsule())
            } else {
                Text(item.cooldownEndsAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
