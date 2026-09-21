import FamilyControls
import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var step: Step = .welcome

    enum Step: Int, CaseIterable {
        case welcome
        case selectApps
        case chooseHabits
        case done
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .welcome:
                    WelcomeStep(onContinue: { step = .selectApps })
                case .selectApps:
                    SelectAppsStep(onContinue: { step = .chooseHabits })
                case .chooseHabits:
                    ChooseHabitsStep(onContinue: { step = .done })
                case .done:
                    DoneStep(onFinish: { model.finishOnboarding() })
                }
            }
            .padding()
            .navigationTitle("初期設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct WelcomeStep: View {
    @Environment(AppModel.self) private var model
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("開いたアプリを、習慣に置き換える")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("選んだアプリを開くと制限画面が表示され、決めた習慣を終えるまで使えなくなります。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = model.authorizationError {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            if model.isAuthorized {
                Button("次へ", action: onContinue)
                    .buttonStyle(.borderedProminent)
            } else {
                Button("スクリーンタイムの利用を許可") {
                    Task {
                        await model.requestAuthorization()
                        if model.isAuthorized { onContinue() }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct SelectAppsStep: View {
    @Environment(AppModel.self) private var model
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("置き換えたいアプリを選ぶ")
                    .font(.title3.bold())
                Text("Instagramなど、つい開いてしまうアプリを選んでください。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if model.configuration.rules.isEmpty {
                ContentUnavailableView("まだ選ばれていません", systemImage: "apps.iphone")
            } else {
                List(model.configuration.rules) { rule in
                    Label(rule.token)
                }
                .listStyle(.plain)
            }

            Button("アプリを選ぶ") { isPickerPresented = true }
                .buttonStyle(.bordered)

            Button("次へ", action: onContinue)
                .buttonStyle(.borderedProminent)
                .disabled(model.configuration.rules.isEmpty)
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .onAppear { selection = model.configuration.selection }
        .onChange(of: selection) { _, newValue in
            model.updateSelection(newValue)
        }
    }
}

private struct ChooseHabitsStep: View {
    @Environment(AppModel.self) private var model
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("置き換える習慣を決める")
                .font(.title3.bold())

            List {
                ForEach(model.configuration.rules) { rule in
                    NavigationLink {
                        HabitEditorView(rule: rule)
                    } label: {
                        HStack {
                            Label(rule.token)
                            Spacer()
                            Image(systemName: rule.habit.kind.symbolName)
                                .foregroundStyle(.tint)
                            Text(rule.habit.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("解除時間") {
                    Picker("習慣のあとに使える時間", selection: graceBinding) {
                        ForEach([15, 30, 60], id: \.self) { minutes in
                            Text("\(minutes)分").tag(minutes)
                        }
                    }
                }
            }

            Button("次へ", action: onContinue)
                .buttonStyle(.borderedProminent)
        }
    }

    private var graceBinding: Binding<Int> {
        Binding(
            get: { model.configuration.graceMinutes },
            set: { model.updateGraceMinutes($0) }
        )
    }
}

private struct DoneStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("設定が完了しました")
                .font(.title2.bold())
            Text("選んだアプリを開くと制限画面が表示されます。ボタンを押すとこのアプリが開き、習慣を実行できます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button("はじめる", action: onFinish)
                .buttonStyle(.borderedProminent)
        }
    }
}
