import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storeService = StoreService.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)
                    Text("Premium'a Geç")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 14) {
                        FeatureRow(icon: "infinity", text: "Sınırsız istek takibi")
                        FeatureRow(icon: "slider.horizontal.3", text: "Özel soğuma süreleri (12 saat - 7 gün)")
                        FeatureRow(icon: "chart.bar.fill", text: "Gelişmiş istatistikler")
                        FeatureRow(icon: "paintbrush.fill", text: "Özel paylaşım temaları")
                    }
                    .padding(.horizontal, 8)

                    if storeService.products.isEmpty {
                        ProgressView()
                            .task { await storeService.loadProducts() }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(storeService.products) { product in
                                Button {
                                    purchase(product)
                                } label: {
                                    HStack {
                                        Text(product.displayName)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Text(product.displayPrice)
                                            .bold()
                                    }
                                    .padding()
                                    .background(.thinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(isPurchasing)
                            }
                        }
                    }

                    Button("Satın alımları geri yükle") {
                        Task { await storeService.restore() }
                    }
                    .font(.footnote)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onChange(of: storeService.isPremium) { _, isPremium in
                if isPremium { dismiss() }
            }
        }
    }

    private func purchase(_ product: Product) {
        isPurchasing = true
        errorMessage = nil
        Task {
            do {
                _ = try await storeService.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
            isPurchasing = false
        }
    }
}
