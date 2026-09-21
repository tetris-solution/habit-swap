import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.route {
        case .onboarding:
            OnboardingView()
        case .home:
            HomeView()
        case .habitSession(let rule):
            HabitSessionView(rule: rule)
        }
    }
}
