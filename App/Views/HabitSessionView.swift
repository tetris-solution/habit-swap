import SwiftUI

struct HabitSessionView: View {
    @Environment(AppModel.self) private var model
    let rule: HabitRule

    @State private var remaining: Int
    @State private var isFinished = false
    @State private var isInhaling = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(rule: HabitRule) {
        self.rule = rule
        _remaining = State(initialValue: rule.habit.durationSeconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Label(rule.token)
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
                Text(rule.habit.title)
                    .font(.largeTitle.bold())
                Text(rule.habit.message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            breathingCircle

            if isFinished {
                VStack(spacing: 12) {
                    Text("おつかれさまでした")
                        .font(.headline)
                    Button("\(model.configuration.graceMinutes)分だけ使う") {
                        model.completeHabit(for: rule)
                    }
                    .buttonStyle(.borderedProminent)
                    Button("やめておく") { model.cancelHabit() }
                        .buttonStyle(.bordered)
                }
            } else {
                VStack(spacing: 12) {
                    Text("残り \(remaining)秒")
                        .font(.title2.monospacedDigit())
                    Button("やめておく") { model.cancelHabit() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .onReceive(timer) { _ in tick() }
        .onAppear { isInhaling = true }
    }

    private var breathingCircle: some View {
        Circle()
            .fill(.tint.opacity(0.25))
            .overlay {
                Image(systemName: rule.habit.kind.symbolName)
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
            }
            .frame(width: 200, height: 200)
            .scaleEffect(isInhaling ? 1.0 : 0.7)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isInhaling)
    }

    private func tick() {
        guard !isFinished else { return }
        remaining -= 1
        if remaining <= 0 {
            remaining = 0
            isFinished = true
        }
    }
}
