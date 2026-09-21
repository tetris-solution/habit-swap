import FamilyControls
import Foundation
import ManagedSettings

enum HabitKind: String, Codable, CaseIterable, Identifiable {
    case breathing
    case stretch
    case water
    case journal
    case walk
    case custom

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .breathing: return "深呼吸"
        case .stretch: return "ストレッチ"
        case .water: return "水を飲む"
        case .journal: return "ひとこと日記"
        case .walk: return "少し歩く"
        case .custom: return "自分で決めた習慣"
        }
    }

    var defaultMessage: String {
        switch self {
        case .breathing: return "まず深呼吸を3回しましょう"
        case .stretch: return "肩を回して伸びをしましょう"
        case .water: return "コップ一杯の水を飲みましょう"
        case .journal: return "いま感じていることを一行だけ書きましょう"
        case .walk: return "立ち上がって少し歩きましょう"
        case .custom: return "決めた習慣をひとつ実行しましょう"
        }
    }

    var defaultDuration: Int {
        switch self {
        case .breathing: return 45
        case .stretch: return 60
        case .water: return 30
        case .journal: return 60
        case .walk: return 120
        case .custom: return 60
        }
    }

    var symbolName: String {
        switch self {
        case .breathing: return "wind"
        case .stretch: return "figure.cooldown"
        case .water: return "drop.fill"
        case .journal: return "square.and.pencil"
        case .walk: return "figure.walk"
        case .custom: return "star.fill"
        }
    }
}

struct Habit: Codable, Hashable {
    var kind: HabitKind
    var title: String
    var message: String
    var durationSeconds: Int

    init(kind: HabitKind) {
        self.kind = kind
        title = kind.defaultTitle
        message = kind.defaultMessage
        durationSeconds = kind.defaultDuration
    }

    init(kind: HabitKind, title: String, message: String, durationSeconds: Int) {
        self.kind = kind
        self.title = title
        self.message = message
        self.durationSeconds = durationSeconds
    }
}

struct HabitRule: Codable, Hashable, Identifiable {
    var id: UUID
    var token: ApplicationToken
    var habit: Habit

    init(id: UUID = UUID(), token: ApplicationToken, habit: Habit) {
        self.id = id
        self.token = token
        self.habit = habit
    }
}

struct GraceGrant: Codable, Hashable {
    var token: ApplicationToken
    var expiresAt: Date

    var isActive: Bool { expiresAt > Date() }
}

struct PendingHabit: Codable, Hashable {
    var token: ApplicationToken
    var requestedAt: Date
}

struct AppConfiguration: Codable {
    var selection: FamilyActivitySelection
    var rules: [HabitRule]
    var graceMinutes: Int
    var onboardingCompleted: Bool

    static let `default` = AppConfiguration(
        selection: FamilyActivitySelection(),
        rules: [],
        graceMinutes: 5,
        onboardingCompleted: false
    )

    func habit(for token: ApplicationToken) -> Habit? {
        rules.first { $0.token == token }?.habit
    }
}
