import DeviceActivity
import Foundation
import ManagedSettings

extension ManagedSettingsStore.Name {
    static let habitSwap = Self("habitswap")
}

extension DeviceActivityName {
    static let graceWindow = Self("habitswap.grace")
}

/// Minimum length Device Activity accepts for a monitored interval.
let minimumGraceMinutes = 15

/// Applies and refreshes the shields, shared by the app and the extensions.
final class ShieldController {
    static let shared = ShieldController()

    private let store = ManagedSettingsStore(named: .habitSwap)
    private let sharedStore: SharedStore
    private let center = DeviceActivityCenter()

    init(sharedStore: SharedStore = .shared) {
        self.sharedStore = sharedStore
    }

    /// Shields every selected app except the ones with an active grace grant.
    func refresh() {
        let configuration = sharedStore.configuration
        guard configuration.onboardingCompleted else {
            clear()
            return
        }

        let excused = Set(sharedStore.grants.map(\.token))
        let shielded = configuration.selection.applicationTokens.subtracting(excused)
        store.shield.applications = shielded.isEmpty ? nil : shielded
    }

    func clear() {
        store.shield.applications = nil
        center.stopMonitoring([.graceWindow])
    }

    /// Unshields one app for a while, then lets Device Activity re-apply the shield.
    func startGrace(for token: ApplicationToken, minutes: Int) {
        let minutes = max(minutes, minimumGraceMinutes)
        let grant = sharedStore.addGrant(for: token, minutes: minutes)
        refresh()
        scheduleEnd(at: grant.expiresAt)
    }

    func endGrace(for token: ApplicationToken) {
        sharedStore.removeGrant(for: token)
        refresh()
    }

    private func scheduleEnd(at date: Date) {
        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: Date()),
            intervalEnd: calendar.dateComponents([.hour, .minute], from: date),
            repeats: false
        )
        center.stopMonitoring([.graceWindow])
        try? center.startMonitoring(.graceWindow, during: schedule)
    }
}
