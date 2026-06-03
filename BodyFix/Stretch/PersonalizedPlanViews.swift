import SwiftUI
import SwiftData

struct PersonalizedPlanDetailView: View {
    @Binding var path: NavigationPath
    var showsBackButton: Bool = true
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]
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

    private var activeOverrides: [String: Int] {
        StretchTimingStore.durationOverrideMap(
            kind: .livePersonalizedPlan,
            ownerId: StretchTimingStore.livePlanOwnerId,
            overrides: timingOverrides
        )
    }

    private var activeRepOverrides: [String: Int] {
        StretchTimingStore.repOverrideMap(
            kind: .livePersonalizedPlan,
            ownerId: StretchTimingStore.livePlanOwnerId,
            overrides: timingOverrides
        )
    }

    private var displayModel: PersonalizedPlanDisplayModel {
        .from(
            plan: currentPlan,
            recommendation: recommendation,
            profile: profile,
            stretches: stretches,
            eyebrow: "Based on your profile",
            title: "Your plan"
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    topBar

                    if routine != nil, !stretches.isEmpty {
                        PersonalizedPlanPreviewHeader(model: displayModel)
                        PersonalizedPlanFirstStepCard(
                            firstStretch: stretches.first,
                            title: displayModel.firstStepTitle
                        )
                        PersonalizedPlanStretchList(
                            stretches: stretches,
                            durationOverrides: activeOverrides,
                            repOverrides: activeRepOverrides,
                            onDecrease: {
                                adjustValue(
                                    for: $0,
                                    delta: $0.isRepBased
                                        ? -StretchTimingStore.repAdjustmentStep
                                        : -StretchTimingStore.adjustmentStep
                                )
                            },
                            onIncrease: {
                                adjustValue(
                                    for: $0,
                                    delta: $0.isRepBased
                                        ? StretchTimingStore.repAdjustmentStep
                                        : StretchTimingStore.adjustmentStep
                                )
                            }
                        )
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 166)
            }

            if let routine, !stretches.isEmpty {
                OnboardingContinueButton(label: "Start Plan", style: .gradientPrimary, feedback: .heavy) {
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
                .padding(.horizontal, 20)
                .padding(.bottom, 84)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            ensurePlanExists()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
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

            Spacer(minLength: 0)

            if routine != nil {
                headerActions
            }
        }
    }

    private var headerActions: some View {
        HStack(spacing: 8) {
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

    private func ensurePlanExists() {
        guard let profile, currentPlan == nil else { return }
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: nil, in: modelContext)
        try? modelContext.save()
    }

    private func regeneratePlan() {
        guard let profile else { return }
        HapticManager.shared.mediumImpact()
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: currentPlan, in: modelContext)
        try? modelContext.save()
    }

    private func adjustValue(for stretch: Stretch, delta: Int) {
        if stretch.isRepBased {
            let updated = StretchTimingStore.adjustedRepCount(for: stretch, delta: delta, overrides: activeRepOverrides)
            StretchTimingStore.setRepCount(
                for: stretch,
                repCount: updated,
                ownerKind: .livePersonalizedPlan,
                ownerId: StretchTimingStore.livePlanOwnerId,
                overrides: timingOverrides,
                in: modelContext
            )
        } else {
            let updated = StretchTimingStore.adjustedDuration(for: stretch, delta: delta, overrides: activeOverrides)
            StretchTimingStore.setDuration(
                for: stretch,
                durationSeconds: updated,
                ownerKind: .livePersonalizedPlan,
                ownerId: StretchTimingStore.livePlanOwnerId,
                overrides: timingOverrides,
                in: modelContext
            )
        }
        try? modelContext.save()
    }
}

struct PersonalizedPlanEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var plans: [PersonalizedPlan]

    @State private var selectedGoals: Set<String> = []
    @State private var selectedAreas: Set<String> = []
    @State private var lifestyle: String = ""
    @State private var dailyTime: String = ""
    @State private var commitmentDays: String = ""
    @State private var longTermGoal: String = ""
    @State private var didLoad = false
    @State private var hasChanges = false

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 10)]

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
                        chipGrid(OnboardingPainArea.allCases.map(\.displayName), selection: $selectedAreas)
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

                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 184)
            }

            GradientButton(title: "Regenerate Plan", showShadow: false) {
                saveAndRegenerate()
            }
            .opacity(hasChanges ? 1 : 0.45)
            .disabled(!hasChanges)
            .padding(.horizontal, 20)
            .padding(.bottom, 84)
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
                    if isSelected {
                        HapticManager.shared.selection()
                        selection.wrappedValue.remove(item)
                        hasChanges = true
                    } else if limit == nil || selection.wrappedValue.count < limit! {
                        HapticManager.shared.selection()
                        selection.wrappedValue.insert(item)
                        hasChanges = true
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
                    guard selection.wrappedValue != item else { return }
                    HapticManager.shared.selection()
                    selection.wrappedValue = item
                    hasChanges = true
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
        selectedAreas = Set(profile.problemAreas)
        lifestyle = profile.lifestyle
        dailyTime = profile.dailyTime
        commitmentDays = profile.commitmentDays
        longTermGoal = profile.longTermGoal
        didLoad = true
    }

    private func saveAndRegenerate() {
        guard let profile else { return }
        HapticManager.shared.success()
        profile.bodyGoals = Array(selectedGoals).sorted()
        profile.problemAreas = Array(selectedAreas).sorted()
        profile.lifestyle = lifestyle
        profile.dailyTime = dailyTime
        profile.commitmentDays = commitmentDays
        profile.longTermGoal = longTermGoal
        PersonalizedPlanGenerator.upsertPlan(for: profile, existing: currentPlan, in: modelContext)
        try? modelContext.save()
        dismiss()
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
