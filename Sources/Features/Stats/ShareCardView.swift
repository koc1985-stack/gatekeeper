import SwiftUI

struct ShareCardView: View {
    let saved: Double
    let hours: Double
    let currencyCode: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white)
            Text("Dürtüsel Alışverişi Durdurdum")
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(CurrencyFormatter.format(saved, currencyCode: currencyCode))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
            Text("biriktirdim")
                .foregroundStyle(.white.opacity(0.85))
            Divider()
                .overlay { Color.white.opacity(0.3) }
                .padding(.horizontal, 40)
            Text("\(WageCalculator.formattedHours(hours)) kazandım")
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(32)
        .frame(width: 320, height: 400)
        .background(
            LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
