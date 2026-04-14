import SwiftUI
import SwiftData

struct PersonalizedPlanDetailView: View {
    @Binding var path: NavigationPath
    var showsBackButton: Bool = true
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]
    @Query private var savedRoutines: [SavedRoutine]
    @Query private var timingOverrides: [StretchTimingOverride]

    private var profile: UserProfile? { profiles.first }
    private var currentPlan: PersonalizedPlan? { plans.max(by: { $0.updatedAt < $1.updatedAt }) }
    private var recommendation: PersonalizedPlanRecommendation? { profile.map(PersonalizedPlanGenerator.recommendation(for:)) }

    private var routine: Routine? {
        if let currentPlan, let stored = StretchDatabase.routine(id: currentPlan.routineId) {
            return stored
        }
        return recommendation?.routine
    }

    private var stretches: [Stretch] {
        if let currentPlan {
            return PersonalizedPlanGenerator.stretches(for: currentPlan, fallbackProfile: profile)
        }
        return recommendation?.stretches ?? []
    }

    private var totalSeconds: Int {
        StretchTimingStore.totalDuration(for: stretches, overrides: activeOverrides)
    }

    private var livePlanSaved: Bool {
        SavedRoutineStore.isLivePlanSaved(in: savedRoutines)
    }

    private var ownerId: String {
        StretchTimingStore.livePlanOwnerId
    }

    private var activeOverrides: [String: Int] {
        StretchTimingStore.durationOverrideMap(kind: .livePersonalizedPlan, ownerId: ownerId, overrides: timingOverrides)
    }

    private var activeRepOverrides: [String: Int] {
        StretchTimingStore.repOverrideMap(kind: .livePersonalizedPlan, ownerId: ownerId, overrides: timingOverrides)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if let routine {
                        planHero(routine: routine)
                        whyCard
                        stretchesSection
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 184)
            }

            if let routine {
                startPlanAction(routine: routine)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 72)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            ensurePlanExists()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsBackButton {
                Button {
                    HapticManager.shared.softImpact()
                    path.removeLast()
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

            VStack(alignment: .leading, spacing: 8) {
                if routine != nil {
                    HStack {
                        Spacer(minLength: 0)
                        headerActions
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    Text("Your plan")
                        .font(Typography.screenTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                }
            }
        }
    }

    private func planHero(routine: Routine) -> some View {
        HStack(spacing: 10) {
            planBadge("\(stretches.count) stretches")
            planBadge(planDurationLabel(totalSeconds))
            if let first = (currentPlan?.sourceProblemAreas.first ?? recommendation?.focusAreas.first) {
                planBadge(first)
            }
        }
    }

    private var whyCard: some View {
        Text(currentPlan?.rationale ?? recommendation?.rationale ?? "This routine reflects the goals and areas you told us matter most.")
            .font(Typography.caption)
            .foregroundStyle(Color.bfTextSecondary)
    }

    private var stretchesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What your plan includes")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            ForEach(Array(stretches.enumerated()), id: \.element.id) { index, stretch in
                PlanStretchRow(
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

    private var headerActions: some View {
        HStack(spacing: 8) {
            Menu {
                Button(livePlanSaved ? "Remove current plan" : "Save current plan") {
                    toggleLivePlanSave()
                }

                if currentPlan != nil {
                    Button("Save this snapshot") {
                        saveSnapshot()
                    }
                }
            } label: {
                Image(systemName: livePlanSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(livePlanSaved ? Color.bfAccent : Color.bfTextMuted)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.bfSurfaceElevated))
                    .overlay(
                        Circle()
                            .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
                    )
            }
            .accessibilityLabel(livePlanSaved ? "Saved plan options" : "Save plan options")

            Button {
                HapticManager.shared.lightImpact()
                path.append(PersonalizedPlanEditorRoute())
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Update")
                        .font(Typography.caption.weight(.semibold))
                }
                .foregroundStyle(Color.bfTextPrimary)
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background(Capsule().fill(Color.bfSurfaceElevated))
                .overlay(
                    Capsule()
                        .stroke(Color.bfBorder.opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Update plan")

            Button {
                regeneratePlan()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.bfAccent)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.bfSurfaceMuted))
                    .overlay(
                        Circle()
                            .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh plan")
        }
    }

    private func startPlanAction(routine: Routine) -> some View {
        VStack(spacing: 0) {
            GradientButton(title: "Start Plan") {
                HapticManager.shared.mediumImpact()
                path.append(
                    StretchTimingStore.timerRoute(
                        stretchIds: stretches.map(\.id),
                        startIndex: 0,
                        routineName: routine.name,
                        durationOverrides: activeOverrides,
                        repOverrides: activeRepOverrides
                    )
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.bfPageBackground.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, y: 4)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No plan yet")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("Complete onboarding or refresh from your current profile to generate your first Body Fix plan.")
                .font(Typography.controlLabel)
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

    private func planBadge(_ title: String) -> some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(Color.bfAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.bfSurfaceMuted))
    }

    private func planDurationLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 && remainder > 0 { return "\(minutes)m \(remainder)s" }
        if minutes > 0 { return "\(minutes)m" }
        return "\(remainder)s"
    }

    private func ensurePlanExists() {
        guard let profile, currentPlan == nil else { return }
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: nil, in: modelContext)
        try? modelContext.save()
    }

    private func regeneratePlan() {
        guard let profile else { return }
        HapticManager.shared.mediumImpact()
        let refreshedPlan = PersonalizedPlanGenerator.upsertPlan(for: profile, existing: currentPlan, in: modelContext)
        SavedRoutineStore.refreshLivePlanFavorite(
            plan: refreshedPlan,
            routine: StretchDatabase.routine(id: refreshedPlan.routineId),
            saved: savedRoutines
        )
        try? modelContext.save()
    }

    private func toggleLivePlanSave() {
        guard let currentPlan else { return }
        HapticManager.shared.lightImpact()
        _ = SavedRoutineStore.toggleLivePlan(
            plan: currentPlan,
            routine: routine,
            saved: savedRoutines,
            in: modelContext
        )
        try? modelContext.save()
    }

    private func saveSnapshot() {
        guard let currentPlan else { return }
        HapticManager.shared.success()
        SavedRoutineStore.savePlanSnapshot(
            plan: currentPlan,
            routine: routine,
            title: routine?.name ?? "Body Fix plan snapshot",
            summary: currentPlan.summary,
            in: modelContext
        )
        try? modelContext.save()
    }

    private func adjustValue(for stretch: Stretch, delta: Int) {
        if stretch.isRepBased {
            let updated = StretchTimingStore.adjustedRepCount(for: stretch, delta: delta, overrides: activeRepOverrides)
            StretchTimingStore.setRepCount(
                for: stretch,
                repCount: updated,
                ownerKind: .livePersonalizedPlan,
                ownerId: ownerId,
                overrides: timingOverrides,
                in: modelContext
            )
        } else {
            let updated = StretchTimingStore.adjustedDuration(for: stretch, delta: delta, overrides: activeOverrides)
            StretchTimingStore.setDuration(
                for: stretch,
                durationSeconds: updated,
                ownerKind: .livePersonalizedPlan,
                ownerId: ownerId,
                overrides: timingOverrides,
                in: modelContext
            )
        }
        try? modelContext.save()
    }
}

private struct PlanStretchRow: View {
    let stretch: Stretch
    let detailText: String
    let valueText: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
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
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.5), lineWidth: 1)
        )
    }
}

struct PersonalizedPlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]
    @Query private var savedRoutines: [SavedRoutine]

    @State private var selectedGoals: Set<String> = []
    @State private var selectedAreas: Set<String> = []
    @State private var lifestyle: String = ""
    @State private var dailyTime: String = ""
    @State private var commitmentDays: String = ""
    @State private var longTermGoal: String = ""
    @State private var selectedHealthConditions: Set<String> = []
    @State private var didLoad = false
    @State private var initialGoals: Set<String> = []
    @State private var initialAreas: Set<String> = []
    @State private var initialLifestyle: String = ""
    @State private var initialDailyTime: String = ""
    @State private var initialCommitmentDays: String = ""
    @State private var initialLongTermGoal: String = ""
    @State private var initialHealthConditions: Set<String> = []

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]
    private let areaOptions = OnboardingPainArea.allCases.map(\.displayName)

    private var profile: UserProfile? { profiles.first }
    private var currentPlan: PersonalizedPlan? { plans.max(by: { $0.updatedAt < $1.updatedAt }) }

    private let goals = [
        "Reduce pain and stiffness",
        "Improve Flexibility",
        "Improve posture",
        "Recover faster from workouts",
        "Reduce stress and tension",
        "Sleep better",
        "Move better day to day",
    ]

    private let longTermGoals = [
        "Become pain-free",
        "Build a lasting stretch routine",
        "Improve athletic performance",
        "Age with mobility and ease",
    ]

    private let lifestyleOptions = [
        "Mostly at a desk",
        "Studying or in class a lot",
        "On my feet most of the day",
        "Physically active job",
        "Training regularly",
    ]

    private let durationOptions = [
        "2 minutes", "3 minutes", "5 minutes", "10 minutes", "15 minutes", "20+ minutes",
    ]

    private let commitmentOptions = [
        "1 day", "2 days", "3 days", "4 days", "5 days", "6 days", "Every day",
    ]

    private let healthOptions = [
        "Arthritis", "Chronic Pain", "Dizziness", "Fibromyalgia", "Heart Condition",
        "Herniated Disc", "High Blood Pressure", "Injury", "Osteoporosis",
        "Pregnancy", "Sciatica", "Surgery", "Vertigo",
    ]

    private var canSave: Bool {
        !selectedGoals.isEmpty
            && !selectedAreas.isEmpty
            && !lifestyle.isEmpty
            && !dailyTime.isEmpty
            && !commitmentDays.isEmpty
            && !longTermGoal.isEmpty
    }

    private var hasChanges: Bool {
        selectedGoals != initialGoals
            || selectedAreas != initialAreas
            || lifestyle != initialLifestyle
            || dailyTime != initialDailyTime
            || commitmentDays != initialCommitmentDays
            || longTermGoal != initialLongTermGoal
            || selectedHealthConditions != initialHealthConditions
    }

    private var canRegenerate: Bool {
        canSave && hasChanges
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            HapticManager.shared.softImpact()
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(Typography.navIcon)
                                .foregroundStyle(Color.bfTextPrimary)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Color.bfSurfaceElevated))
                                .overlay(Circle().stroke(Color.bfBorder.opacity(0.75), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Text("Update your plan")
                            .font(Typography.screenTitle)
                            .foregroundStyle(Color.bfTextPrimary)

                        Text("Adjust the inputs that shape your routine, then regenerate your Body Fix plan.")
                            .font(Typography.screenSubtitle)
                            .foregroundStyle(Color.bfTextSecondary)
                    }

                    editorSection(title: "Goals", subtitle: "Choose up to 3.") {
                        chipGrid(goals, selection: $selectedGoals, limit: 3)
                    }

                    editorSection(title: "Problem areas", subtitle: "Pick what matters most right now.") {
                        chipGrid(areaOptions, selection: $selectedAreas)
                    }

                    editorSection(title: "Lifestyle", subtitle: nil) {
                        singleSelectGrid(lifestyleOptions, selection: $lifestyle)
                    }

                    editorSection(title: "Daily time", subtitle: nil) {
                        singleSelectGrid(durationOptions, selection: $dailyTime)
                    }

                    editorSection(title: "Commitment", subtitle: nil) {
                        singleSelectGrid(commitmentOptions, selection: $commitmentDays)
                    }

                    editorSection(title: "Long-term goal", subtitle: nil) {
                        singleSelectGrid(longTermGoals, selection: $longTermGoal)
                    }

                    editorSection(title: "Health conditions", subtitle: "Optional.") {
                        chipGrid(healthOptions, selection: $selectedHealthConditions)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 176)
            }

            GradientButton(title: "Regenerate Plan", showShadow: false) {
                saveAndRegenerate()
            }
            .opacity(canRegenerate ? 1 : 0.45)
            .disabled(!canRegenerate)
            .padding(.horizontal, 20)
            .padding(.bottom, 72)
        }
        .background(Color.bfPageBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            loadFromProfileIfNeeded()
        }
    }

    private func editorSection<Content: View>(title: String, subtitle: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextSecondary)
                }
            }

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.48), lineWidth: 1)
        )
    }

    private func chipGrid(_ items: [String], selection: Binding<Set<String>>, limit: Int? = nil) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection.wrappedValue.contains(item)
                Button {
                    HapticManager.shared.selection()
                    if isSelected {
                        selection.wrappedValue.remove(item)
                    } else if limit == nil || selection.wrappedValue.count < limit! {
                        selection.wrappedValue.insert(item)
                    }
                } label: {
                    PlanChoiceChip(title: item, isSelected: isSelected)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func singleSelectGrid(_ items: [String], selection: Binding<String>) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                Button {
                    HapticManager.shared.selection()
                    selection.wrappedValue = item
                } label: {
                    PlanChoiceChip(title: item, isSelected: selection.wrappedValue == item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func loadFromProfileIfNeeded() {
        guard !didLoad, let profile else { return }
        selectedGoals = Set(profile.bodyGoals)
        selectedAreas = Set(profile.problemAreas.compactMap(displayProblemArea(fromStoredValue:)))
        lifestyle = profile.lifestyle
        dailyTime = profile.dailyTime
        commitmentDays = profile.commitmentDays
        longTermGoal = profile.longTermGoal
        selectedHealthConditions = Set(profile.healthConditions)
        initialGoals = selectedGoals
        initialAreas = selectedAreas
        initialLifestyle = lifestyle
        initialDailyTime = dailyTime
        initialCommitmentDays = commitmentDays
        initialLongTermGoal = longTermGoal
        initialHealthConditions = selectedHealthConditions
        didLoad = true
    }

    private func saveAndRegenerate() {
        guard let profile, canRegenerate else { return }
        HapticManager.shared.success()
        profile.bodyGoals = Array(selectedGoals).sorted()
        profile.problemAreas = selectedAreas
            .compactMap(storedProblemArea(fromDisplayValue:))
            .sorted()
        profile.lifestyle = lifestyle
        profile.dailyTime = dailyTime
        profile.commitmentDays = commitmentDays
        profile.longTermGoal = longTermGoal
        profile.healthConditions = Array(selectedHealthConditions).sorted()
        let refreshedPlan = PersonalizedPlanGenerator.upsertPlan(for: profile, existing: currentPlan, in: modelContext)
        SavedRoutineStore.refreshLivePlanFavorite(
            plan: refreshedPlan,
            routine: StretchDatabase.routine(id: refreshedPlan.routineId),
            saved: savedRoutines
        )
        try? modelContext.save()
        dismiss()
    }

    private func displayProblemArea(fromStoredValue value: String) -> String? {
        OnboardingPainArea.allCases.first { area in
            area.rawValue == value || area.displayName.caseInsensitiveCompare(value) == .orderedSame
        }?.displayName
    }

    private func storedProblemArea(fromDisplayValue value: String) -> String? {
        OnboardingPainArea.allCases.first { area in
            area.displayName.caseInsensitiveCompare(value) == .orderedSame || area.rawValue == value
        }?.rawValue
    }
}

private struct PlanChoiceChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(isSelected ? Color.white : Color.bfTextPrimary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.bfGradient) : AnyShapeStyle(Color.bfSurfaceMuted))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.bfBorder.opacity(0.42), lineWidth: 1)
            )
    }
}
