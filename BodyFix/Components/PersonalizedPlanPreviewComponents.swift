import SwiftUI

struct PersonalizedPlanDisplayModel {
    let stretches: [Stretch]
    let totalSeconds: Int
    let focusAreas: [String]

    static func from(
        plan: PersonalizedPlan?,
        recommendation: PersonalizedPlanRecommendation?,
        profile: UserProfile?,
        stretches: [Stretch]
    ) -> PersonalizedPlanDisplayModel {
        let totalSeconds: Int = {
            if let plan, plan.targetDurationSeconds > 0 { return plan.targetDurationSeconds }
            if let recommendation { return recommendation.totalSeconds }
            return stretches.reduce(0) { $0 + $1.duration }
        }()

        let focusAreas: [String] = {
            if let plan, !plan.sourceProblemAreas.isEmpty { return plan.sourceProblemAreas }
            if let recommendation { return recommendation.focusAreas }
            return profile?.problemAreas ?? []
        }()

        return PersonalizedPlanDisplayModel(
            stretches: stretches,
            totalSeconds: totalSeconds,
            focusAreas: focusAreas
        )
    }

    static func from(recommendation: PersonalizedPlanRecommendation) -> PersonalizedPlanDisplayModel {
        PersonalizedPlanDisplayModel(
            stretches: recommendation.stretches,
            totalSeconds: recommendation.totalSeconds,
            focusAreas: recommendation.focusAreas
        )
    }

    static func planDurationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(remainder)s"
    }
}

struct PersonalizedPlanSpotlightCard: View {
    let model: PersonalizedPlanDisplayModel
    let profile: UserProfile?

    private var featuredStretches: [Stretch] {
        Array(model.stretches.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                spotlightBadge

                Text(model.personalizedTitle(profile: profile))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bfHeroTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)

                Text(model.spotlightSubtitle)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.bfHeroTextSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !featuredStretches.isEmpty {
                HStack(spacing: 6) {
                    ForEach(featuredStretches) { stretch in
                        BodyFixThumbnailView(stretch: stretch, size: 46, isFeatured: true)
                    }
                }
                .padding(.top, 2)
            }

            HStack(spacing: 8) {
                spotlightMeta("\(model.stretches.count) stretches")
                    .layoutPriority(1)
                spotlightDivider
                spotlightMeta(PersonalizedPlanDisplayModel.planDurationLabel(model.totalSeconds))
                    .layoutPriority(1)
                spotlightDivider
                spotlightMeta(model.spotlightFocusLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .layoutPriority(0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(spotlightBackground)
        .shadow(color: Color.bfHeroSurface.opacity(0.18), radius: 18, y: 8)
    }

    private var spotlightBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))

            Text("Made just for you")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.bfHeroTextPrimary.opacity(0.95))
        .lineLimit(1)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(Color.white.opacity(0.12)))
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private var spotlightDivider: some View {
        Text("·")
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Color.bfHeroTextSecondary.opacity(0.62))
    }

    private func spotlightMeta(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(Color.bfHeroTextSecondary)
            .lineLimit(1)
    }

    private var spotlightBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.bfHeroSurface, Color.bfHeroSurfaceSecondary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(Color.bfHeroGhostCircle.opacity(0.55))
                    .frame(width: 168, height: 168)
                    .offset(x: 42, y: -60)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.bfAccent.opacity(0.18))
                    .frame(width: 142, height: 142)
                    .offset(x: 54, y: 58)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension PersonalizedPlanDisplayModel {
    func personalizedTitle(profile: UserProfile?) -> String {
        let firstName = profile?.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .first
            .map(String.init) ?? ""

        guard !firstName.isEmpty else { return "Your plan" }
        return "\(firstName)'s plan"
    }

    var spotlightSubtitle: String {
        "Tailored to your \(formattedFocusAreas)."
    }

    var spotlightFocusLabel: String {
        normalizedFocusAreas.first.map { "\($0.capitalized) focus" } ?? "Full body focus"
    }

    var formattedFocusAreas: String {
        switch normalizedFocusAreas.count {
        case 0:
            return "body"
        case 1:
            return normalizedFocusAreas[0]
        case 2:
            return "\(normalizedFocusAreas[0]) & \(normalizedFocusAreas[1])"
        default:
            return normalizedFocusAreas.joined(separator: ", ")
        }
    }

    private var normalizedFocusAreas: [String] {
        focusAreas.compactMap { area in
            let trimmed = area.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed.lowercased()
        }
    }
}

struct PersonalizedPlanStretchList: View {
    let stretches: [Stretch]
    let durationOverrides: [String: Int]
    let repOverrides: [String: Int]
    let onDecrease: (Stretch) -> Void
    let onIncrease: (Stretch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your first session")
                .font(Typography.sectionTitle)
                .foregroundStyle(.bfTextPrimary)

            ForEach(Array(stretches.enumerated()), id: \.element.id) { index, stretch in
                PersonalizedPlanStretchRow(
                    stretch: stretch,
                    isFirstStep: index == 0,
                    detailText: StretchTimingStore.detailText(
                        for: stretch,
                        durationOverrides: durationOverrides,
                        repOverrides: repOverrides
                    ),
                    valueText: StretchTimingStore.controlLabel(
                        for: stretch,
                        durationOverrides: durationOverrides,
                        repOverrides: repOverrides
                    ),
                    onDecrease: { onDecrease(stretch) },
                    onIncrease: { onIncrease(stretch) }
                )
            }
        }
    }
}

struct PersonalizedPlanStretchRow: View {
    let stretch: Stretch
    let isFirstStep: Bool
    let detailText: String
    let valueText: String?
    let onDecrease: (() -> Void)?
    let onIncrease: (() -> Void)?
    let firstStepLabel: String
    let firstStepSystemImage: String?

    init(
        stretch: Stretch,
        isFirstStep: Bool,
        detailText: String? = nil,
        valueText: String? = nil,
        onDecrease: (() -> Void)? = nil,
        onIncrease: (() -> Void)? = nil,
        firstStepLabel: String = "Start here",
        firstStepSystemImage: String? = nil
    ) {
        self.stretch = stretch
        self.isFirstStep = isFirstStep
        self.detailText = detailText ?? StretchTimingStore.detailText(for: stretch, durationOverrides: [:])
        self.valueText = valueText
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
        self.firstStepLabel = firstStepLabel
        self.firstStepSystemImage = firstStepSystemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            BodyFixThumbnailView(stretch: stretch, size: 52)

            VStack(alignment: .leading, spacing: 5) {
                if isFirstStep {
                    HStack(spacing: 5) {
                        if let firstStepSystemImage {
                            Image(systemName: firstStepSystemImage)
                                .font(.system(size: 10, weight: .bold))
                        }

                        Text(firstStepLabel)
                            .lineLimit(1)
                    }
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.bfAccent.opacity(0.1)))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(stretch.name)
                        .font(Typography.controlLabel)
                        .foregroundStyle(.bfTextPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detailText)
                        .font(Typography.caption)
                        .foregroundStyle(.bfTextSecondary)
                        .lineLimit(2)
                }

                if let valueText, let onDecrease, let onIncrease {
                    HStack {
                        Spacer(minLength: 0)

                        StretchTimingAdjuster(
                            valueText: valueText,
                            onDecrease: onDecrease,
                            onIncrease: onIncrease
                        )
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isFirstStep ? Color.bfAccent.opacity(0.28) : Color.bfBorder.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isFirstStep ? 0.035 : 0.02), radius: isFirstStep ? 10 : 8, y: 3)
    }
}
