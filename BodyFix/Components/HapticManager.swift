import UIKit

final class HapticManager {
    static let shared = HapticManager()
    static let enabledKey = "haptics_enabled"

    enum Feedback {
        case none
        case selection
        case soft
        case light
        case medium
        case heavy
        case success
        case warning
        case error
    }

    private init() {}

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    func play(_ feedback: Feedback) {
        switch feedback {
        case .none:
            break
        case .selection:
            selection()
        case .soft:
            softImpact()
        case .light:
            lightImpact()
        case .medium:
            mediumImpact()
        case .heavy:
            heavyImpact()
        case .success:
            success()
        case .warning:
            warning()
        case .error:
            error()
        }
    }

    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    func lightImpact() {
        guard isEnabled else { return }
        lightImpactGenerator.impactOccurred()
    }

    func softImpact() {
        guard isEnabled else { return }
        softImpactGenerator.impactOccurred()
    }

    func mediumImpact() {
        guard isEnabled else { return }
        mediumImpactGenerator.impactOccurred()
    }

    func heavyImpact() {
        guard isEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }

    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }

    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    func prepare() {
        guard isEnabled else { return }
        selectionGenerator.prepare()
        lightImpactGenerator.prepare()
        softImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()
    }
}
