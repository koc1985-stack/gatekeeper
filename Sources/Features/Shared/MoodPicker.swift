import SwiftUI

struct MoodPicker: View {
    @Binding var selection: Mood?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases) { mood in
                Button {
                    selection = (selection == mood) ? nil : mood
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 28))
                        Text(mood.displayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(selection == mood ? Color.orange.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == mood ? Color.orange : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
