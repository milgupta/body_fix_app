import SwiftUI

enum Typography {
    static let appHeadline = Font.system(size: 36, weight: .bold, design: .rounded)
    static let onboardingQuestion = Font.system(size: 38, weight: .bold, design: .rounded)
    static let onboardingSupport = Font.system(size: 19, weight: .medium, design: .rounded)
    static let sectionTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let cardTitle = Font.system(size: 16, weight: .bold, design: .rounded)
    static let controlLabel = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let tabLabel = Font.system(size: 11, weight: .semibold, design: .rounded)
    static let metadataBadge = Font.system(size: 11, weight: .bold, design: .monospaced)

    static let navIcon = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let subtitle = onboardingSupport
    static let question = onboardingQuestion
    static let optionText = controlLabel
    static let ctaButton = Font.system(size: 20, weight: .bold, design: .rounded)
    static let sliderValue = Font.system(size: 52, weight: .bold, design: .rounded)
    static let caption = Font.system(size: 15, weight: .medium, design: .rounded)
    static let splashTitle = Font.system(size: 38, weight: .bold, design: .rounded)

    static let screenTitle = appHeadline
    static let screenSubtitle = Font.system(size: 16, weight: .medium, design: .rounded)
    static let navTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let muscleCardLabel = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let stretchName = cardTitle
    static let stretchDescription = Font.system(size: 14, weight: .regular, design: .rounded)
    static let badgeMono = metadataBadge
    static let tapHint = Font.system(size: 11, weight: .semibold, design: .monospaced)
    static let timerMonoLarge = Font.system(size: 48, weight: .thin, design: .monospaced)
    static let timerLabelSmall = Font.system(size: 10, weight: .semibold, design: .monospaced)
    static let primaryCta = Font.system(size: 18, weight: .bold, design: .rounded)
}
