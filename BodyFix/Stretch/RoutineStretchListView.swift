import SwiftUI
import SwiftData

struct RoutineStretchListView: View {
    let route: RoutineStretchListRoute
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var savedRoutines: [SavedRoutine]
    @Query private var timingOverrides: [StretchTimingOverride]

    private var routine: Routine? {
        StretchDatabase.routine(id: route.routineId)
    }

    private var stretches: [Stretch] {
        guard let routine else { return [] }
        return StretchDatabase.stretches(for: routine)
    }

    private var isSaved: Bool {
        guard let routine else { return false }
        return SavedRoutineStore.presetFavorite(for: routine.id, in: savedRoutines) != nil
    }

    private var ownerId: String {
        route.routineId
    }

    private var activeOverrides: [String: Int] {
        StretchTimingStore.durationOverrideMap(kind: .presetRoutine, ownerId: ownerId, overrides: timingOverrides)
    }

    private var activeRepOverrides: [String: Int] {
        StretchTimingStore.repOverrideMap(kind: .presetRoutine, ownerId: ownerId, overrides: timingOverrides)
    }

    private var totalDurationSeconds: Int {
        StretchTimingStore.totalDuration(for: stretches, overrides: activeOverrides)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    ForEach(stretches) { stretch in
                        RoutineStretchRow(
                            stretch: stretch,
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
                            onTap: {
                                HapticManager.shared.lightImpact()
                                let ids = stretches.map(\.id)
                                if let idx = ids.firstIndex(of: stretch.id) {
                                    path.append(
                                        StretchTimingStore.timerRoute(
                                            stretchIds: ids,
                                            startIndex: idx,
                                            routineName: routine?.name,
                                            seriesId: routine?.seriesId,
                                            seriesLevel: routine?.level,
                                            durationOverrides: activeOverrides,
                                            repOverrides: activeRepOverrides
                                        )
                                    )
                                }
                            },
                            onDecrease: {
                                adjustValue(for: stretch, delta: stretch.isRepBased ? -StretchTimingStore.repAdjustmentStep : -StretchTimingStore.adjustmentStep)
                            },
                            onIncrease: {
                                adjustValue(for: stretch, delta: stretch.isRepBased ? StretchTimingStore.repAdjustmentStep : StretchTimingStore.adjustmentStep)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, stretches.isEmpty ? 40 : 176)
            }

            if !stretches.isEmpty {
                GradientButton(title: "Start Routine") {
                    HapticManager.shared.heavyImpact()
                    path.append(
                        StretchTimingStore.timerRoute(
                            stretchIds: stretches.map(\.id),
                            startIndex: 0,
                            routineName: routine?.name,
                            seriesId: routine?.seriesId,
                            seriesLevel: routine?.level,
                            durationOverrides: activeOverrides,
                            repOverrides: activeRepOverrides
                        )
                    )
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

            ToolbarItem(placement: .topBarTrailing) {
                if let routine {
                    Button {
                        toggleSave(routine)
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(isSaved ? Color.bfAccent : Color.bfTextMuted)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.bfSurfaceElevated))
                            .overlay(Circle().stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isSaved ? "Remove saved routine" : "Save routine")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let routine {
                HStack(alignment: .top, spacing: 14) {
                    BodyFixThumbnailView(routine: routine, size: 68)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(StretchTimingStore.minutesLabel(seconds: totalDurationSeconds))
                            .font(Typography.homeMeta)
                            .foregroundStyle(Color.bfMint)

                        Text(routine.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.bfTextPrimary)
                            .lineSpacing(-1)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                Text("\(stretches.count) stretches")
                    .font(Typography.screenSubtitle)
                    .foregroundStyle(Color.bfTextTertiary)
            } else {
                Text("Routine unavailable")
                    .font(Typography.screenTitle)
                    .foregroundStyle(Color.bfTextPrimary)
            }
        }
        .padding(.top, 12)
    }

    private func toggleSave(_ routine: Routine) {
        HapticManager.shared.mediumImpact()
        _ = SavedRoutineStore.togglePreset(routine: routine, saved: savedRoutines, in: modelContext)
        try? modelContext.save()
    }

    private func adjustValue(for stretch: Stretch, delta: Int) {
        if stretch.isRepBased {
            let updated = StretchTimingStore.adjustedRepCount(for: stretch, delta: delta, overrides: activeRepOverrides)
            StretchTimingStore.setRepCount(
                for: stretch,
                repCount: updated,
                ownerKind: .presetRoutine,
                ownerId: ownerId,
                overrides: timingOverrides,
                in: modelContext
            )
        } else {
            let updated = StretchTimingStore.adjustedDuration(for: stretch, delta: delta, overrides: activeOverrides)
            StretchTimingStore.setDuration(
                for: stretch,
                durationSeconds: updated,
                ownerKind: .presetRoutine,
                ownerId: ownerId,
                overrides: timingOverrides,
                in: modelContext
            )
        }
        try? modelContext.save()
    }
}

private struct RoutineStretchRow: View {
    let stretch: Stretch
    let detailText: String
    let valueText: String
    let onTap: () -> Void
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    BodyFixThumbnailView(stretch: stretch, size: 52)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(stretch.name)
                            .font(Typography.stretchName)
                            .foregroundStyle(Color.bfTextPrimary)
                            .multilineTextAlignment(.leading)

                        Text(detailText)
                            .font(Typography.stretchDescription)
                            .foregroundStyle(Color.bfTextTertiary)
                            .lineLimit(2)
                    }

            Spacer(minLength: 8)

            StretchTimingAdjuster(
                valueText: valueText,
                onDecrease: onDecrease,
                        onIncrease: onIncrease
                    )
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green.opacity(0.85))
                        .frame(width: 6, height: 6)
                    Text("TAP TO START")
                        .font(Typography.tapHint)
                        .foregroundStyle(Color.bfTextMuted)
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.bfSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(Color.bfBorder.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
