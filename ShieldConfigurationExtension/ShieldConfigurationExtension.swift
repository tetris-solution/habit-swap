import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    private let store = SharedStore.shared

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        guard let token = application.token, let habit = store.configuration.habit(for: token) else {
            return defaultConfiguration(
                title: "ちょっと待って",
                subtitle: "このアプリの代わりに、決めた習慣をやってみましょう"
            )
        }
        return defaultConfiguration(title: habit.title, subtitle: habit.message)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        defaultConfiguration(
            title: "ちょっと待って",
            subtitle: "このサイトの代わりに、決めた習慣をやってみましょう"
        )
    }

    private func defaultConfiguration(title: String, subtitle: String) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1),
            icon: UIImage(systemName: "wind"),
            title: ShieldConfiguration.Label(text: title, color: .white),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "習慣をはじめる", color: .white),
            primaryButtonBackgroundColor: UIColor(red: 0.25, green: 0.52, blue: 0.96, alpha: 1),
            secondaryButtonLabel: ShieldConfiguration.Label(text: "閉じる", color: .lightGray)
        )
    }
}
