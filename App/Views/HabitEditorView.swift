import SwiftUI

struct HabitEditorView: View {
    @Environment(AppModel.self) private var model
    let rule: HabitRule

    @State private var habit: Habit

    init(rule: HabitRule) {
        self.rule = rule
        _habit = State(initialValue: rule.habit)
    }

    var body: some View {
        Form {
            Section("対象アプリ") {
                Label(rule.token)
            }

            Section("習慣") {
                Picker("種類", selection: $habit.kind) {
                    ForEach(HabitKind.allCases) { kind in
                        Label(kind.defaultTitle, systemImage: kind.symbolName).tag(kind)
                    }
                }
                TextField("タイトル", text: $habit.title)
                TextField("制限画面に出す文章", text: $habit.message, axis: .vertical)
                Stepper("所要時間 \(habit.durationSeconds)秒", value: $habit.durationSeconds, in: 15...300, step: 15)
            }
        }
        .navigationTitle("習慣の設定")
        .onChange(of: habit.kind) { _, kind in
            habit.title = kind.defaultTitle
            habit.message = kind.defaultMessage
            habit.durationSeconds = kind.defaultDuration
        }
        .onDisappear { model.updateHabit(habit, for: rule.id) }
    }
}
