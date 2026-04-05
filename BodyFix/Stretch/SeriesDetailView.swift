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
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("SERIES")
                            .font(Typography.badgeMono)
                            .foregroundStyle(Color.bfMint)

                        Text(series?.name ?? "Series")
                            .font(Typography.screenTitle)
                            .foregroundStyle(Color.bfTextPrimary)

                        Text(series?.difficultyLabel ?? "Progressive program")
                            .font(Typography.screenSubtitle)
                            .foregroundStyle(Color.bfTextTertiary)
                    }
                    .padding(.top, 8)

                    ForEach(levelRoutines) { routine in
                        Button {
                            HapticManager.shared.mediumImpact()
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
                .padding(.bottom, 120)
            }

            if let nextRoutine {
                GradientButton(title: "Start \(nextRoutine.name)") {
                    HapticManager.shared.heavyImpact()
                    path.append(RoutineStretchListRoute(routineId: nextRoutine.id))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticManager.shared.mediumImpact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.navIcon)
                        .foregroundStyle(Color.bfMint)
                }
            }
        }
    }
}

private struct SeriesLevelCard: View {
    let routine: Routine
    let isCompleted: Bool
    let isNext: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    BodyFixThumbnailView(routine: routine, size: 44)

                    Text(routine.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bfTextPrimary)
                }
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.bfMint)
                }
            }

            HStack(spacing: 10) {
                ForEach(1...3, id: \.self) { level in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(level <= (routine.level ?? 0) && isCompleted ? Color.bfMint : (level == (routine.level ?? 0) ? Color.bfBlue : Color.bfBorder))
                            .frame(width: 10, height: 10)
                        Text(levelLabel(level))
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(Color.bfTextMuted)
                    }
                    if level < 3 {
                        Rectangle()
                            .fill(Color.bfBorder)
                            .frame(height: 2)
                    }
                }
            }

            HStack {
                Text(routine.durationLabel)
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.bfMint)
                Spacer()
                if isNext && !isCompleted {
                    Text("NEXT")
                        .font(Typography.badgeMono)
                        .foregroundStyle(Color.bfBlue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isNext ? Color.bfBlue.opacity(0.35) : Color.bfBorder, lineWidth: 1)
        )
    }

    private func levelLabel(_ level: Int) -> String {
        switch level {
        case 1: return "I"
        case 2: return "II"
        default: return "III"
        }
    }
}
