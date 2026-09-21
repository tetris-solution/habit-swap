import DeviceActivity

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        guard activity == .graceWindow else { return }
        ShieldController.shared.refresh()
    }
}
