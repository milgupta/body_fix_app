import SwiftUI
import SwiftData

@MainActor
struct WorkoutLogView: View {
    @Binding var selectedTab: Int
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedRoutine.updatedAt, order: .reverse) private var savedRoutines: [SavedRoutine]
    @Query private var plans: [PersonalizedPlan]

    private var currentPlan: PersonalizedPlan? {
        plans.max(by: { $0.updatedAt < $1.updatedAt })
    }

    private var livePlanFavorite: SavedRoutine? {
        SavedRoutineStore.livePlanFavorite(in: savedRoutines)
    }

    private var snapshotFavorites: [SavedRoutine] {
        savedRoutines.filter { $0.kind == .planSnapshot }
    }

    private var presetFavorites: [SavedRoutine] {
        savedRoutines.filter { $0.kind == .presetRoutine }
    }

    private var hasCurrentPlan: Bool {
        currentPlan != nil
    }

    var body: some View {
        ZStack {
            Color.bfBackground.ignoresSafeArea()

            if savedRoutines.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        if let livePlanFavorite {
                            favoriteSectionLabel("YOUR CURRENT PLAN")

                            SavedFavoriteRow(
                                onRemove: { removeFavorite(livePlanFavorite) }
                            ) {
                                HapticManager.shared.lightImpact()
                                path.append(PersonalizedPlanRoute())
                            } content: {
                                SavedRoutineCard(
                                    title: "Your current plan",
                                    subtitle: currentPlan?.summary ?? livePlanFavorite.displaySummary,
                                    detail: durationLabel(currentPlan?.targetDurationSeconds ?? livePlanFavorite.durationSeconds),
                                    tag: "Live plan",
                                    thumbnail: .stretch(stretch(for: currentPlan?.stretchIds.first ?? livePlanFavorite.stretchIds.first))
                                )
                            }
                        }

                        if !snapshotFavorites.isEmpty {
                            favoriteSectionLabel("PLAN SNAPSHOTS")

                            ForEach(snapshotFavorites) { favorite in
                                SavedFavoriteRow(
                                    onRemove: { removeFavorite(favorite) }
                                ) {
                                    HapticManager.shared.lightImpact()
                                    path.append(SavedPlanDetailRoute(savedRoutineId: favorite.id))
                                } content: {
                                    SavedRoutineCard(
                                        title: favorite.displayTitle,
                                        subtitle: favorite.displaySummary,
                                        detail: durationLabel(favorite.durationSeconds),
                                        tag: "Snapshot",
                                        thumbnail: .stretch(stretch(for: favorite.stretchIds.first))
                                    )
                                }
                            }
                        }

                        if !presetFavorites.isEmpty {
                            favoriteSectionLabel("ROUTINES")

                            ForEach(presetFavorites) { favorite in
                                if let routineId = favorite.routineId, let routine = StretchDatabase.routine(id: routineId) {
                                    SavedFavoriteRow(
                                        onRemove: { removeFavorite(favorite) }
                                    ) {
                                        HapticManager.shared.lightImpact()
                                        path.append(RoutineStretchListRoute(routineId: routine.id))
                                    } content: {
                                        SavedRoutineCard(
                                            title: routine.name,
                                            subtitle: "\(routine.stretchIds.count) stretches",
                                            detail: StretchDatabase.durationLabel(for: routine),
                                            tag: "Routine",
                                            thumbnail: .routine(routine)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 128)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Saved")
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("Keep your favorite preset routines and custom plans in one place.")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Text("🧘")
                .font(.system(size: 60))

            VStack(spacing: 8) {
                Text("No saved routines yet")
                    .font(Typography.cardTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                Text("Save preset routines or your custom plan to come back to them quickly.")
                    .font(Typography.screenSubtitle)
                    .foregroundStyle(Color.bfTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }

            Button {
                HapticManager.shared.mediumImpact()
                selectedTab = hasCurrentPlan ? 1 : 0
            } label: {
                Text(hasCurrentPlan ? "Go to your plan" : "Explore routines")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.bfGradient)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func favoriteSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(Typography.badgeMono)
            .foregroundStyle(Color.bfTextMuted)
    }

    private func durationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return minutes == 1 ? "1 min" : "\(minutes) min" }
        return "\(max(seconds, 0))s"
    }

    private func stretch(for id: String?) -> Stretch? {
        guard let id else { return nil }
        return StretchDatabase.stretch(id: id)
    }

    private func removeFavorite(_ favorite: SavedRoutine) {
        HapticManager.shared.softImpact()
        withAnimation(.easeInOut(duration: 0.25)) {
            SavedRoutineStore.remove(favorite, in: modelContext)
        }
    }
}

private struct SavedFavoriteRow<Content: View>: View {
    let onRemove: () -> Void
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Button(action: action, label: content)
                .buttonStyle(.plain)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.bfTextMuted)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.bfSurfaceMuted)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove from saved")
        }
    }
}

private struct SavedRoutineCard: View {
    enum ThumbnailKind {
        case routine(Routine)
        case stretch(Stretch?)
    }

    let title: String
    let subtitle: String
    let detail: String
    let tag: String
    let thumbnail: ThumbnailKind

    var body: some View {
        HStack(spacing: 14) {
            thumbnailView

            VStack(alignment: .leading, spacing: 6) {
                Text(tag.uppercased())
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.bfAccent)

                Text(title)
                    .font(Typography.controlLabel)
                    .foregroundStyle(Color.bfTextPrimary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)

            Text(detail)
                .font(Typography.caption)
                .foregroundStyle(Color.bfTextMuted)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var thumbnailView: some View {
        switch thumbnail {
        case .routine(let routine):
            BodyFixThumbnailView(routine: routine, size: 58)
        case .stretch(let stretch):
            if let stretch {
                BodyFixThumbnailView(stretch: stretch, size: 58)
            } else {
                placeholderThumbnail
            }
        }
    }

    private var placeholderThumbnail: some View {
        Circle()
            .fill(Color.bfSurfaceMuted)
            .frame(width: 58, height: 58)
            .overlay(
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.bfAccent)
            )
    }
}

#Preview {
    WorkoutLogView(selectedTab: .constant(0), path: .constant(NavigationPath()))
        .modelContainer(for: [SavedRoutine.self, PersonalizedPlan.self, UserProfile.self], inMemory: true)
}
