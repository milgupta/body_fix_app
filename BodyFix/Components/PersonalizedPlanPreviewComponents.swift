import SwiftUI

struct PersonalizedPlanDisplayModel {
    let eyebrow: String
    let title: String
    let summary: String
    let stretches: [Stretch]
    let totalSeconds: Int
    let focusAreas: [String]

    var firstStepTitle: String {
        stretches.first?.name ?? "Start your first stretch"
    }

    static func from(
        plan: PersonalizedPlan?,
        recommendation: PersonalizedPlanRecommendation?,
        profile: UserProfile?,
        stretches: [Stretch],
        eyebrow: String,
        title: String
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

        let summary = headerSummary(totalSeconds: totalSeconds, focusAreas: focusAreas)

        return PersonalizedPlanDisplayModel(
            eyebrow: eyebrow,
            title: title,
            summary: summary,
            stretches: stretches,
            totalSeconds: totalSeconds,
            focusAreas: focusAreas
        )
    }

    static func from(recommendation: PersonalizedPlanRecommendation, eyebrow: String, title: String) -> PersonalizedPlanDisplayModel {
        PersonalizedPlanDisplayModel(
            eyebrow: eyebrow,
            title: title,
            summary: headerSummary(totalSeconds: recommendation.totalSeconds, focusAreas: recommendation.focusAreas),
            stretches: recommendation.stretches,
            totalSeconds: recommendation.totalSeconds,
            focusAreas: recommendation.focusAreas
        )
    }

    static func headerSummary(totalSeconds: Int, focusAreas: [String]) -> String {
        let duration = planDurationLabel(totalSeconds)
        let areaPhrase = focusAreas.first.map { $0.lowercased() }

        if let areaPhrase {
            return "Start with a \(duration) routine built for your \(areaPhrase) needs and daily rhythm."
        }
        return "Start with a \(duration) routine built from what you told us."
    }

    static func planDurationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(remainder)s"
    }
}

struct PersonalizedPlanPreviewHeader: View {
    let model: PersonalizedPlanDisplayModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text(model.eyebrow)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bfAccent.opacity(0.96))
                    .lineLimit(1)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.bfAccent.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.bfAccent.opacity(0.26), lineWidth: 1)
                    )

                Text(model.title)
                    .font(Typography.screenTitle)
                    .foregroundStyle(.bfTextPrimary)

                Text(model.summary)
                    .font(Typography.screenSubtitle)
                    .foregroundStyle(.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                planPreviewBadge(title: "\(model.stretches.count) stretches", allowsCompression: false)
                planPreviewBadge(title: PersonalizedPlanDisplayModel.planDurationLabel(model.totalSeconds), allowsCompression: false)

                if let firstArea = model.focusAreas.first {
                    planPreviewBadge(title: firstArea)
                }

                if model.focusAreas.count > 1 {
                    planPreviewBadge(title: "\(model.focusAreas.count - 1)+")
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(personalizedPlanHeaderPanel)
    }
}

struct PersonalizedPlanFirstStepCard: View {
    let firstStretch: Stretch?
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            if let firstStretch {
                BodyFixThumbnailView(stretch: firstStretch, size: 50)
            } else {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.bfAccent))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Today's first step")
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfAccent)

                Text(title)
                    .font(Typography.controlLabel)
                    .foregroundStyle(Color.bfTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Begin here. We'll guide you through each hold.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfAccent.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)
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

    init(
        stretch: Stretch,
        isFirstStep: Bool,
        detailText: String? = nil,
        valueText: String? = nil,
        onDecrease: (() -> Void)? = nil,
        onIncrease: (() -> Void)? = nil
    ) {
        self.stretch = stretch
        self.isFirstStep = isFirstStep
        self.detailText = detailText ?? StretchTimingStore.detailText(for: stretch, durationOverrides: [:])
        self.valueText = valueText
        self.onDecrease = onDecrease
        self.onIncrease = onIncrease
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            BodyFixThumbnailView(stretch: stretch, size: 52)

            VStack(alignment: .leading, spacing: 5) {
                if isFirstStep {
                    Text("Start here")
                        .font(Typography.metadataBadge)
                        .foregroundStyle(Color.bfAccent)
                        .lineLimit(1)
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

func planPreviewBadge(title: String, allowsCompression: Bool = true) -> some View {
    Text(title)
        .font(Typography.caption)
        .foregroundStyle(Color.bfAccent)
        .lineLimit(1)
        .truncationMode(.tail)
        .fixedSize(horizontal: !allowsCompression, vertical: false)
        .layoutPriority(allowsCompression ? 0 : 1)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.86))
        )
        .overlay(
            Capsule()
                .stroke(Color.bfAccent.opacity(0.18), lineWidth: 1)
        )
}

var personalizedPlanHeaderPanel: some View {
    RoundedRectangle(cornerRadius: 28, style: .continuous)
        .fill(
            LinearGradient(
                colors: [
                    Color(hex: "#F5FAFF"),
                    Color(hex: "#EAF3FF"),
                    Color.bfSurfaceElevated.opacity(0.96),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.bfAccent.opacity(0.16))
                .frame(width: 168, height: 168)
                .blur(radius: 22)
                .offset(x: -48, y: -58)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.bfBlue.opacity(0.12))
                .frame(width: 128, height: 128)
                .blur(radius: 24)
                .offset(x: 42, y: 42)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.bfAccent.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.bfAccent.opacity(0.08), radius: 18, y: 8)
}
