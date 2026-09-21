import Foundation
import ManagedSettings

enum AppGroup {
    static let identifier = "group.jp.tetris-solution.habitswap"
}

/// Storage shared between the app and its Screen Time extensions.
final class SharedStore {
    static let shared = SharedStore()

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let configuration = "configuration"
        static let grants = "grants"
        static let pendingHabit = "pendingHabit"
        static let completedCount = "completedCount"
    }

    init(defaults: UserDefaults = UserDefaults(suiteName: AppGroup.identifier) ?? .standard) {
        self.defaults = defaults
    }

    var configuration: AppConfiguration {
        get { read(Key.configuration) ?? .default }
        set { write(newValue, for: Key.configuration) }
    }

    var grants: [GraceGrant] {
        get { (read(Key.grants) ?? []).filter(\.isActive) }
        set { write(newValue.filter(\.isActive), for: Key.grants) }
    }

    var pendingHabit: PendingHabit? {
        get { read(Key.pendingHabit) }
        set { write(newValue, for: Key.pendingHabit) }
    }

    var completedCount: Int {
        get { defaults.integer(forKey: Key.completedCount) }
        set { defaults.set(newValue, forKey: Key.completedCount) }
    }

    func grant(for token: ApplicationToken) -> GraceGrant? {
        grants.first { $0.token == token && $0.isActive }
    }

    func addGrant(for token: ApplicationToken, minutes: Int) -> GraceGrant {
        let grant = GraceGrant(token: token, expiresAt: Date().addingTimeInterval(TimeInterval(minutes * 60)))
        grants = grants.filter { $0.token != token } + [grant]
        return grant
    }

    func removeGrant(for token: ApplicationToken) {
        grants = grants.filter { $0.token != token }
    }

    private func read<T: Decodable>(_ key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T?, for key: String) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }
        defaults.set(try? encoder.encode(value), forKey: key)
    }
}
