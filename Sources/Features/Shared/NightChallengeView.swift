import SwiftUI

/// Extra friction shown before logging a purchase at night: a 15-second hold, or a quick math
/// question. Not meant to be unbeatable — just enough to interrupt an impulsive tap.
struct NightChallengeView: View {
    let challenge: NightChallenge
    let onPassed: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isPressing = false
    @State private var holdProgress: Double = 0
    @State private var mathAnswer = ""
    @State private var showWrongAnswer = false
    @State private var mathA = Int.random(in: 10...49)
    @State private var mathB = Int.random(in: 10...49)

    private let holdDuration: Double = 15
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.indigo)
                VStack(spacing: 8) {
                    Text("Gece Kuşu Kilidi")
                        .font(.title.bold())
                    Text("Gece geç saatte alışveriş genelde anlık bir dürtüdür. Devam etmeden önce bir adım daha at.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                switch challenge {
                case .hold:
                    holdChallenge
                case .math:
                    mathChallenge
                }

                Spacer()
                Button("Vazgeç") {
                    onCancel()
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
            .onReceive(timer) { _ in
                guard challenge == .hold, isPressing, holdProgress < holdDuration else { return }
                holdProgress = min(holdDuration, holdProgress + 0.05)
                if holdProgress >= holdDuration {
                    onPassed()
                    dismiss()
                }
            }
        }
    }

    private var holdChallenge: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: holdProgress / holdDuration)
                    .stroke(Color.indigo, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(max(0, Int((holdDuration - holdProgress).rounded(.up))))")
                    .font(.title.bold())
            }
            .frame(width: 120, height: 120)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressing = true }
                    .onEnded { _ in
                        isPressing = false
                        if holdProgress < holdDuration { holdProgress = 0 }
                    }
            )
            Text("15 saniye boyunca parmağını bu daireden çekme")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var mathChallenge: some View {
        VStack(spacing: 16) {
            Text("\(mathA) + \(mathB) = ?")
                .font(.title.bold())
            TextField("Cevap", text: $mathAnswer)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
            if showWrongAnswer {
                Text("Yanlış cevap, tekrar dene")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button("Devam Et") {
                if Int(mathAnswer) == mathA + mathB {
                    onPassed()
                    dismiss()
                } else {
                    showWrongAnswer = true
                    mathAnswer = ""
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(mathAnswer.isEmpty)
        }
    }
}
