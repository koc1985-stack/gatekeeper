import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [UserSettings]
    @State private var step: Int = 0

    private var settings: UserSettings {
        if let existing = settingsList.first { return existing }
        let created = UserSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        Group {
            switch step {
            case 0:
                WelcomeView(onContinue: { step = 1 })
            case 1:
                WageInputView(onContinue: { step = 2 })
            default:
                NotificationPermissionView(onFinish: finish)
            }
        }
        .animation(.default, value: step)
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
    }
}
