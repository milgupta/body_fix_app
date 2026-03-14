import UIKit

final class HapticManager {
    static let shared = HapticManager()
    private init() {}

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func selection() {
        selectionGenerator.selectionChanged()
    }

    func lightImpact() {
        lightImpactGenerator.impactOccurred()
    }

    func softImpact() {
        softImpactGenerator.impactOccurred()
    }

    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    func prepare() {
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        softImpactGenerator.prepare()
    }
}
