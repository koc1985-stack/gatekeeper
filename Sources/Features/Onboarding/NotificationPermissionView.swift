import SwiftUI

struct NotificationPermissionView: View {
    let onFinish: () -> Void
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("Hatırlatmalara İzin Ver")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Soğuma süresi bittiğinde sana haber verelim ki kararını unutma.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
            Button("Bildirimlere İzin Ver") {
                isRequesting = true
                Task {
                    await NotificationService.shared.requestAuthorization()
                    isRequesting = false
                    onFinish()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .disabled(isRequesting)
            Button("Şimdi Değil", action: onFinish)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}
