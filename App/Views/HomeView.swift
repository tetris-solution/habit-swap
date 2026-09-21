import FamilyControls
import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("こなした習慣")
                        Spacer()
                        Text("\(model.completedCount)回")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("置き換えルール") {
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
                    Button("アプリを選び直す") { isPickerPresented = true }
                }

                Section("解除時間") {
                    Picker("習慣のあとに使える時間", selection: graceBinding) {
                        ForEach([15, 30, 60], id: \.self) { minutes in
                            Text("\(minutes)分").tag(minutes)
                        }
                    }
                }

                Section {
                    Button("初期設定をやり直す", role: .destructive) { model.resetOnboarding() }
                }
            }
            .navigationTitle("HabitSwap")
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .onAppear { selection = model.configuration.selection }
            .onChange(of: selection) { _, newValue in
                model.updateSelection(newValue)
            }
        }
    }

    private var graceBinding: Binding<Int> {
        Binding(
            get: { model.configuration.graceMinutes },
            set: { model.updateGraceMinutes($0) }
        )
    }
}
