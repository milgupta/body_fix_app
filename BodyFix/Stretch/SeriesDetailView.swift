import SwiftUI
import SwiftData

struct SeriesDetailView: View {
    let route: SeriesDetailRoute
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Query private var progressEntries: [RoutineSeriesProgress]

    private var series: RoutineSeries? {
        StretchDatabase.series(id: route.seriesId)
    }

    private var levelRoutines: [Routine] {
        guard let series else { return [] }
        return StretchDatabase.levelRoutines(for: series)
    }

    private var completedLevel: Int {
        progressEntries.first(where: { $0.seriesId == route.seriesId })?.completedLevel ?? 0
    }

    private var nextRoutine: Routine? {
        levelRoutines.first(where: { ($0.level ?? 0) > completedLevel }) ?? levelRoutines.last
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    Text("Tap any level to choose a different step.")
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfTextMuted)

                    ForEach(levelRoutines) { routine in
                        Button {
                            HapticManager.shared.lightImpact()
                            path.append(RoutineStretchListRoute(routineId: routine.id))
                        } label: {
                            SeriesLevelCard(
                                routine: routine,
                                isCompleted: (routine.level ?? 0) <= completedLevel,
                                isNext: routine.id == nextRoutine?.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 146)
            }

            if let nextRoutine {
                VStack(spacing: 8) {
                    Text("Recommended next step")
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfTextMuted)

                    GradientButton(title: ctaTitle(for: nextRoutine)) {
                        HapticManager.shared.heavyImpact()
                        path.append(RoutineStretchListRoute(routineId: nextRoutine.id))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 72)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticManager.shared.softImpact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.navIcon)
                        .foregroundStyle(Color.bfMint)
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Program")
                .font(Typography.homeMeta)
                .foregroundStyle(Color.bfBlue)

            Text(series?.name ?? "Series")
                .font(Typography.homeDisplayTitle)
                .foregroundStyle(Color.bfTextPrimary)
                .lineSpacing(-1)

            Text(series?.difficultyLabel ?? "Progressive program")
                .font(Typography.homeSupport)
                .foregroundStyle(Color.bfTextTertiary)

            if let series {
                Text(seriesDescription(for: series))
                    .font(Typography.homeCardSupport)
                    .foregroundStyle(Color.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
    }

    private func seriesDescription(for series: RoutineSeries) -> String {
        switch series.id {
        case "series_posture":
            return "Build from simple posture resets into stronger, longer sessions that help you move tall and relaxed."
        case "series_lower_back":
            return "Start with gentle decompression and progress into steadier lower-back support across each level."
        case "series_neck_shoulders":
            return "Ease neck and shoulder tension with a structured sequence that grows with your consistency."
        case "series_hips":
            return "Unlock tight hips gradually with a smooth progression from mobility basics to deeper release."
        default:
            return "A guided progression designed to help you stay consistent and build momentum over time."
        }
    }

    private func ctaTitle(for routine: Routine) -> String {
        let level = routine.level ?? 1
        switch level {
        case 1: return "Continue with Step I"
        case 2: return "Continue with Step II"
        case 3: return "Continue with Step III"
        default: return "Start next step"
        }
    }
}

private struct SeriesLevelCard: View {
    let routine: Routine
    let isCompleted: Bool
    let isNext: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                BodyFixThumbnailView(routine: routine, size: 56)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Step \(routine.level ?? 1)")
                            .font(Typography.homeMeta)
                            .foregroundStyle(isNext ? Color.bfBlue : Color.bfTextMuted)

                        Spacer()

                        if isCompleted {
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(Typography.homeMeta)
                                .foregroundStyle(Color.bfMint)
                        } else if isNext {
                            Text("Up next")
                                .font(Typography.homeMeta)
                                .foregroundStyle(Color.bfBlue)
                        }
                    }

                    Text(routine.name)
                        .font(Typography.homeCardTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(-1)

                    Text(StretchDatabase.durationLabel(for: routine))
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfTextSecondary)
                }
            }

            HStack(spacing: 12) {
                ForEach(1...3, id: \.self) { level in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(level < (routine.level ?? 0) ? Color.bfMint.opacity(0.65) : (level == (routine.level ?? 0) ? Color.bfBlue : Color.bfBorder.opacity(0.85)))
                            .frame(width: 12, height: 12)

                        Text(levelLabel(level))
                            .font(Typography.homeMeta)
                            .foregroundStyle(Color.bfTextMuted)
                    }

                    if level < 3 {
                        Capsule()
                            .fill(level < (routine.level ?? 0) ? Color.bfMint.opacity(0.55) : Color.bfBorder.opacity(0.85))
                            .frame(height: 3)
                    }
                }
            }

            Text(routineSupportLine)
                .font(Typography.homeCardSupport)
                .foregroundStyle(Color.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isNext
                            ? [Color.white.opacity(0.98), Color.bfSurfaceElevated, Color.bfBlue.opacity(0.08)]
                            : [Color.bfSurfaceElevated, Color.bfSurfaceMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(isNext ? Color.bfBlue.opacity(0.35) : Color.bfBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.028), radius: 10, y: 4)
    }

    private var routineSupportLine: String {
        if isCompleted { return "You’ve already finished this level. Revisit it anytime for a solid reset." }
        if isNext { return "This is the best next step in your progression when you’re ready to keep going." }
        return "Part of your guided progression, designed to build confidence before the next level."
    }

    private func levelLabel(_ level: Int) -> String {
        switch level {
        case 1: return "I"
        case 2: return "II"
        default: return "III"
        }
    }
}
