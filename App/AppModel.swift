import FamilyControls
import Foundation
import ManagedSettings
import Observation

@MainActor
@Observable
final class AppModel {
    enum Route: Equatable {
        case onboarding
        case home
        case habitSession(HabitRule)
    }

    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    private(set) var authorizationError: String?
    private(set) var completedCount: Int = 0
    var configuration: AppConfiguration

    private let store: SharedStore
    private let shieldController: ShieldController
    private static let pendingLifetime: TimeInterval = 15 * 60

    init(store: SharedStore = .shared, shieldController: ShieldController = .shared) {
        self.store = store
        self.shieldController = shieldController
        configuration = store.configuration
        completedCount = store.completedCount
    }

    var route: Route {
        guard configuration.onboardingCompleted else { return .onboarding }
        if let rule = pendingRule() { return .habitSession(rule) }
        return .home
    }

    var isAuthorized: Bool { authorizationStatus == .approved }

    func refreshAuthorizationStatus() async {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
        }
        await refreshAuthorizationStatus()
    }

    func reload() {
        configuration = store.configuration
        completedCount = store.completedCount
        shieldController.refresh()
    }

    // MARK: - Onboarding

    func updateSelection(_ selection: FamilyActivitySelection) {
        configuration.selection = selection
        let tokens = selection.applicationTokens
        var rules = configuration.rules.filter { tokens.contains($0.token) }
        for token in tokens where !rules.contains(where: { $0.token == token }) {
            rules.append(HabitRule(token: token, habit: Habit(kind: .breathing)))
        }
        configuration.rules = rules
        persist()
    }

    func updateHabit(_ habit: Habit, for ruleID: HabitRule.ID) {
        guard let index = configuration.rules.firstIndex(where: { $0.id == ruleID }) else { return }
        configuration.rules[index].habit = habit
        persist()
    }

    func updateGraceMinutes(_ minutes: Int) {
        configuration.graceMinutes = max(minutes, minimumGraceMinutes)
        persist()
    }

    func finishOnboarding() {
        configuration.onboardingCompleted = true
        persist()
    }

    func resetOnboarding() {
        configuration.onboardingCompleted = false
        persist()
    }

    // MARK: - Habit session

    func completeHabit(for rule: HabitRule) {
        store.pendingHabit = nil
        completedCount += 1
        store.completedCount = completedCount
        shieldController.startGrace(for: rule.token, minutes: configuration.graceMinutes)
    }

    func cancelHabit() {
        store.pendingHabit = nil
        shieldController.refresh()
    }

    private func pendingRule() -> HabitRule? {
        guard let pending = store.pendingHabit else { return nil }
        guard Date().timeIntervalSince(pending.requestedAt) < Self.pendingLifetime else {
            store.pendingHabit = nil
            return nil
        }
        return configuration.rules.first { $0.token == pending.token }
    }

    private func persist() {
        store.configuration = configuration
        shieldController.refresh()
    }
}
