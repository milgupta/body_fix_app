import SwiftUI
import SwiftData

@MainActor
struct SavedPlanDetailView: View {
    let route: SavedPlanDetailRoute
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRoutines: [SavedRoutine]
    @Query private var timingOverrides: [StretchTimingOverride]

    private var savedPlan: SavedRoutine? {
        savedRoutines.first(where: { $0.id == route.savedRoutineId && $0.kind == .planSnapshot })
    }

    private var routine: Routine? {
        guard let routineId = savedPlan?.routineId else { return nil }
        return StretchDatabase.routine(id: routineId)
    }

    private var stretches: [Stretch] {
        guard let savedPlan else { return [] }
        return savedPlan.stretchIds.compactMap(StretchDatabase.stretch(id:))
    }

    private var ownerId: String {
        route.savedRoutineId.uuidString
    }

    private var activeOverrides: [String: Int] {
        StretchTimingStore.durationOverrideMap(kind: .savedPlanSnapshot, ownerId: ownerId, overrides: timingOverrides)
    }

    private var activeRepOverrides: [String: Int] {
        StretchTimingStore.repOverrideMap(kind: .savedPlanSnapshot, ownerId: ownerId, overrides: timingOverrides)
    }

    private var totalDurationSeconds: Int {
        StretchTimingStore.totalDuration(for: stretches, overrides: activeOverrides)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let savedPlan {
                        snapshotHero(savedPlan)
                        snapshotSummary(savedPlan)
                        stretchesSection
                    } else {
                        missingState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 184)
            }

            if let savedPlan, !stretches.isEmpty {
                GradientButton(title: "Start Saved Plan") {
                    HapticManager.shared.heavyImpact()
                    path.append(
                        StretchTimingStore.timerRoute(
                            stretchIds: savedPlan.stretchIds,
                            startIndex: 0,
                            routineId: savedPlan.routineId,
                            routineName: savedPlan.displayTitle,
                            durationOverrides: activeOverrides,
                            repOverrides: activeRepOverrides,
                            showsStartCountdown: true,
                            source: .savedPlan
                        )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 72)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        Button {
            HapticManager.shared.softImpact()
            if path.isEmpty {
                dismiss()
            } else {
                path.removeLast()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(Typography.navIcon)
                .foregroundStyle(Color.bfTextPrimary)
                .frame(width: 42, height: 42)
                .background(Circle().fill(Color.bfSurfaceElevated))
                .overlay(Circle().stroke(Color.bfBorder.opacity(0.75), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func snapshotHero(_ savedPlan: SavedRoutine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let routine {
                BodyFixThumbnailView(routine: routine, size: 72)
            } else if let stretch = stretches.first {
                BodyFixThumbnailView(stretch: stretch, size: 72)
            }

            Text("PLAN SNAPSHOT")
                .font(Typography.badgeMono)
                .foregroundStyle(Color.bfAccent)

            Text(savedPlan.displayTitle)
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)

            HStack(spacing: 10) {
                snapshotBadge("\(stretches.count) stretches")
                snapshotBadge(StretchTimingStore.durationLabel(seconds: totalDurationSeconds))
            }
        }
    }

    private func snapshotSummary(_ savedPlan: SavedRoutine) -> some View {
        Text(savedPlan.displaySummary)
            .font(Typography.screenSubtitle)
            .foregroundStyle(Color.bfTextSecondary)
    }

    private var stretchesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What’s in this snapshot")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            ForEach(Array(stretches.enumerated()), id: \.element.id) { index, stretch in
                SavedPlanStretchRow(
                    stretch: stretch,
                    index: index,
                    detailText: StretchTimingStore.detailText(
                        for: stretch,
                        durationOverrides: activeOverrides,
                        repOverrides: activeRepOverrides
                    ),
                    valueText: StretchTimingStore.controlLabel(
                        for: stretch,
                        durationOverrides: activeOverrides,
                        repOverrides: activeRepOverrides
                    ),
                    onDecrease: {
                        adjustValue(for: stretch, delta: stretch.isRepBased ? -StretchTimingStore.repAdjustmentStep : -StretchTimingStore.adjustmentStep)
                    },
                    onIncrease: {
                        adjustValue(for: stretch, delta: stretch.isRepBased ? StretchTimingStore.repAdjustmentStep : StretchTimingStore.adjustmentStep)
                    }
                )
            }
        }
    }

    private var missingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved plan unavailable")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("This saved snapshot could not be loaded.")
                .font(Typography.caption)
                .foregroundStyle(Color.bfTextSecondary)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.5), lineWidth: 1)
        )
    }

    private func snapshotBadge(_ title: String) -> some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(Color.bfAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.bfSurfaceMuted))
    }

    private func adjustValue(for stretch: Stretch, delta: Int) {
        guard let savedPlan else { return }
        if stretch.isRepBased {
            let updated = StretchTimingStore.adjustedRepCount(for: stretch, delta: delta, overrides: activeRepOverrides)
            StretchTimingStore.setRepCount(
                for: stretch,
                repCount: updated,
                ownerKind: .savedPlanSnapshot,
                ownerId: savedPlan.id.uuidString,
                overrides: timingOverrides,
                in: modelContext
            )
        } else {
            let updated = StretchTimingStore.adjustedDuration(for: stretch, delta: delta, overrides: activeOverrides)
            StretchTimingStore.setDuration(
                for: stretch,
                durationSeconds: updated,
                ownerKind: .savedPlanSnapshot,
                ownerId: savedPlan.id.uuidString,
                overrides: timingOverrides,
                in: modelContext
            )
        }
        try? modelContext.save()
    }
}

private struct SavedPlanStretchRow: View {
    let stretch: Stretch
    let index: Int
    let detailText: String
    let valueText: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.bfSurfaceMuted)
                    .frame(width: 28, height: 28)

                Text("\(index + 1)")
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfAccent)
            }

            BodyFixThumbnailView(stretch: stretch, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(stretch.name)
                    .font(Typography.controlLabel)
                    .foregroundStyle(Color.bfTextPrimary)

                Text(detailText)
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextSecondary)
            }

            Spacer()

            StretchTimingAdjuster(
                valueText: valueText,
                onDecrease: onDecrease,
                onIncrease: onIncrease
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
    }
}
