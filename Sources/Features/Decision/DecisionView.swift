import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct DecisionView: View {
    @Bindable var item: PurchaseItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settingsList: [UserSettings]

    private var hourlyWage: Double { settingsList.first?.effectiveHourlyWage ?? 0 }
    private var hoursRequired: Double { WageCalculator.hoursRequired(price: item.price, hourlyWage: hourlyWage) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 8) {
                    if item.source == .extensionSource, let domain = item.sourceDomain {
                        Label(domain, systemImage: "safari.fill")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    Text(item.name)
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text(CurrencyFormatter.format(item.price, currencyCode: item.currencyCode))
                        .font(.largeTitle.bold())
                        .foregroundStyle(.orange)
                }

                if hourlyWage > 0 {
                    VStack(spacing: 4) {
                        Text("Bunu almak için")
                            .foregroundStyle(.secondary)
                        Text(WageCalculator.formattedHours(hoursRequired))
                            .font(.title2.bold())
                        Text(item.isWaiting ? "çalışman gerekiyor" : "çalışman gerekti")
                            .foregroundStyle(.secondary)
                    }
                }

                if item.price > 0 {
                    VStack(spacing: 4) {
                        Text("Bunun yerine 3 yıl S&P 500'e yatırsaydın")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Text(CurrencyFormatter.format(
                            WageCalculator.projectedValue(principal: item.price, years: 3, annualRate: InvestmentAsset.sp500.annualReturnRate),
                            currencyCode: item.currencyCode
                        ))
                        .font(.headline)
                        .foregroundStyle(.green)
                    }
                }

                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Divider()

                decisionArea
            }
            .padding()
        }
        .navigationTitle("Karar")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var decisionArea: some View {
        if item.isWaiting {
            if item.isCooldownComplete {
                VStack(spacing: 16) {
                    Label("Karar verme zamanı geldi", systemImage: "hourglass.badge.exclamationmark")
                        .font(.headline)
                    HStack(spacing: 16) {
                        Button {
                            decide(bought: false)
                        } label: {
                            Label("Vazgeçtim", systemImage: "hand.raised.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            decide(bought: true)
                        } label: {
                            Label("Aldım", systemImage: "cart.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Label("Soğuma süresi devam ediyor", systemImage: "hourglass")
                        .foregroundStyle(.secondary)
                    Text(item.cooldownEndsAt, style: .relative)
                        .font(.headline)
                }
            }
        } else {
            Label(
                item.status == .bought ? "Bu ürünü aldın" : "Bu üründen vazgeçtin",
                systemImage: item.status == .bought ? "cart.fill" : "checkmark.seal.fill"
            )
            .font(.headline)
            .foregroundStyle(item.status == .bought ? AnyShapeStyle(.secondary) : AnyShapeStyle(.green))
        }
    }

    private func decide(bought: Bool) {
        item.status = bought ? .bought : .skipped
        item.decidedAt = .now
        NotificationService.shared.cancelReminder(for: item)
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
