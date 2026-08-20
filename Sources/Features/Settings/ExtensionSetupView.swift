import SwiftUI
import UIKit

struct ExtensionSetupView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Safari Uzantısını Etkinleştir")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Trendyol, Amazon, Zara ve H&M gibi sitelerde ödeme ekranına geldiğinde otomatik uyarı gösterebilmemiz için uzantıyı Safari'de açman gerekiyor.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 16) {
                    stepRow(number: 1, text: "Aşağıdaki butona bas, Ayarlar uygulaması açılsın")
                    stepRow(number: 2, text: "Safari → Uzantılar → \"Bekle\" uzantısını bul")
                    stepRow(number: 3, text: "Uzantıyı aç ve tüm web siteleri için izin ver")
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Ayarları Aç", systemImage: "gearshape.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("Not: Uzantı sadece ödeme sayfasına geldiğinde devreye girer; gezinme geçmişini takip etmez ya da veri toplamaz, tüm veriler sadece cihazında kalır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Safari Uzantısı")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepRow(number: Int, text: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())
            Text(text)
                .font(.subheadline)
        }
    }
}
