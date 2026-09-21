import SwiftUI

@main
struct HabitSwapApp: App {
    @State private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .task { await model.refreshAuthorizationStatus() }
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    model.reload()
                }
        }
    }
}
