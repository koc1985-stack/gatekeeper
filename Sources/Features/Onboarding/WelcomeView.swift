import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("Dürtüsel Alışverişi Durdur")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Sepete attığın her şey için bir soğuma süresi başlat. Almadan önce bir kez daha düşün.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "cart.badge.clock", text: "İstediğin ürünü kaydet")
                FeatureRow(icon: "hourglass", text: "24 saat bekle, dürtüyü geçir")
                FeatureRow(icon: "clock.badge.questionmark", text: "Kaç saat çalışman gerektiğini gör")
                FeatureRow(icon: "banknote", text: "Vazgeçtikçe biriktir")
            }
            .padding(.horizontal, 32)
            Spacer()
            Button("Başla", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding()
    }
}
