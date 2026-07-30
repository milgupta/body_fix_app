import Foundation
import SwiftData
import Observation

@Observable
class OnboardingViewModel {
    private static let draftDefaultsKey = "bodyfix.onboarding.draft.v1"
    private static let draftSchemaVersion = 1

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private var persistsDraft = false
    @ObservationIgnored private(set) var restoredFromDraft = false

    var currentStep: Int = 0 {
        didSet { persistDraftIfNeeded() }
    }
    let totalSteps: Int = 21

    static let stepIdentifiers = [
        "welcome",
        "name",
        "age_range",
        "long_term_goal",
        "pain_frequency",
        "pain_impact",
        "build_program",
        "problem_areas",
        "activity_level",
        "lifestyle",
        "problem_times",
        "stretching_experience",
        "stretching_outcome",
        "duration",
        "education",
        "commitment",
        "analyzing",
        "signature",
        "motivation",
        "social_proof",
        "plan_preview",
    ]

    // Screen 1: Name
    var userName: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 2: Age Range
    var ageRange: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Retained for profile compatibility and post-onboarding plan editing.
    // Body goals are no longer collected during onboarding.
    var selectedBodyGoals: Set<String> = [] {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 3: Long-Term Goal
    var longTermGoal: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 4: Pain Frequency (1-7)
    var painFrequency: Int = 3 {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 5: Pain Impact (1-10)
    var painImpact: Int = 5 {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 6: Build Program (no input)

    // Screen 7: Pain Awareness
    var selectedPainAreas: Set<OnboardingPainArea> = [] {
        didSet { persistDraftIfNeeded() }
    }
    var problemAreaOtherText: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    var problemAreasForProfile: [String] {
        var areas = selectedPainAreas.filter { $0 != .other }.map(\.rawValue)
        if selectedPainAreas.contains(.other) {
            let custom = problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !custom.isEmpty {
                areas.append(custom)
            }
        }
        return areas
    }

    // Screen 8: Daily Movement
    var activityLevel: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 9: Work/Lifestyle
    var lifestyle: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 10: Problem Times
    var selectedProblemTimes: Set<String> = [] {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 11: Stretching History
    var stretchingFrequency: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 12: Stretching Outcome (no input)

    // Screen 13: Time Commitment
    var dailyTime: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 14: Education (no input)

    // Screen 15: Commitment
    var commitmentDays: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 16: Analyzing (no input)

    // Screen 17: Signature Commitment (kept only until onboarding completes)
    var commitmentSignatureStrokes: [[CGPoint]] = [] {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 18: Motivation Level
    var motivationLevel: String = "" {
        didSet { persistDraftIfNeeded() }
    }

    // Screen 19: Social Proof (no input)

    // Screen 20: Plan Preview (no input)

    init(
        restoresDraft: Bool = false,
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults

        guard restoresDraft, let draft = Self.loadDraft(from: userDefaults) else {
            persistsDraft = restoresDraft
            return
        }

        if let restoredStep = Self.stepIdentifiers.firstIndex(of: draft.stepID) {
            currentStep = restoredStep
        }
        userName = draft.userName
        ageRange = draft.ageRange
        selectedBodyGoals = Set(draft.selectedBodyGoals)
        longTermGoal = draft.longTermGoal
        painFrequency = min(max(draft.painFrequency, 1), 7)
        painImpact = min(max(draft.painImpact, 1), 10)
        selectedPainAreas = Set(
            draft.selectedPainAreaIDs.compactMap(OnboardingPainArea.init(rawValue:))
        )
        problemAreaOtherText = draft.problemAreaOtherText
        activityLevel = draft.activityLevel
        lifestyle = draft.lifestyle
        selectedProblemTimes = Set(draft.selectedProblemTimes)
        stretchingFrequency = draft.stretchingFrequency
        dailyTime = draft.dailyTime
        commitmentDays = draft.commitmentDays
        commitmentSignatureStrokes = draft.commitmentSignatureStrokes
        motivationLevel = draft.motivationLevel
        restoredFromDraft = true
        persistsDraft = true
    }

    var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }

    func analyticsProperties(for step: Int? = nil) -> [String: Any] {
        let index = step ?? currentStep
        var properties: [String: Any] = [
            "step_id": Self.stepIdentifiers.indices.contains(index) ? Self.stepIdentifiers[index] : "unknown",
            "step_index": index,
            "step_number": index + 1,
            "total_steps": totalSteps,
        ]
        if !ageRange.isEmpty {
            properties["age_range"] = ageRange
        }
        return properties
    }

    var canAdvance: Bool {
        switch currentStep {
        case 0: return true
        case 1: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case 2: return !ageRange.isEmpty
        case 3: return !longTermGoal.isEmpty
        case 4: return true
        case 5: return true
        case 6: return true
        case 7:
            guard !selectedPainAreas.isEmpty else { return false }
            if selectedPainAreas.contains(.other) {
                return !problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            return true
        case 8: return !activityLevel.isEmpty
        case 9: return !lifestyle.isEmpty
        case 10: return !selectedProblemTimes.isEmpty
        case 11: return !stretchingFrequency.isEmpty
        case 12: return true
        case 13: return !dailyTime.isEmpty
        case 14: return true
        case 15: return !commitmentDays.isEmpty
        case 16: return true
        case 17: return !commitmentSignatureStrokes.isEmpty
        case 18: return !motivationLevel.isEmpty
        case 19: return true
        case 20: return true
        default: return false
        }
    }

    func advance() {
        guard currentStep < totalSteps - 1 else { return }
        currentStep += 1
    }

    func goBack() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func saveDraft() {
        persistDraftIfNeeded()
    }

    func clearDraft() {
        persistsDraft = false
        userDefaults.removeObject(forKey: Self.draftDefaultsKey)
    }

    @discardableResult
    func saveProfile(to modelContext: ModelContext) -> UserProfile {
        let profile = UserProfile(
            name: userName,
            ageRange: ageRange,
            bodyGoals: Array(selectedBodyGoals),
            longTermGoal: longTermGoal,
            painFrequency: painFrequency,
            painImpact: painImpact,
            activityLevel: activityLevel,
            lifestyle: lifestyle,
            stretchingFrequency: stretchingFrequency,
            dailyTime: dailyTime,
            problemAreas: problemAreasForProfile,
            problemTimes: Array(selectedProblemTimes),
            commitmentDays: commitmentDays,
            onboardingComplete: true
        )
        modelContext.insert(profile)
        return profile
    }

    private func persistDraftIfNeeded() {
        guard persistsDraft else { return }

        let stepID = Self.stepIdentifiers.indices.contains(currentStep)
            ? Self.stepIdentifiers[currentStep]
            : Self.stepIdentifiers[0]
        let draft = OnboardingDraft(
            schemaVersion: Self.draftSchemaVersion,
            stepID: stepID,
            userName: userName,
            ageRange: ageRange,
            selectedBodyGoals: selectedBodyGoals.sorted(),
            longTermGoal: longTermGoal,
            painFrequency: painFrequency,
            painImpact: painImpact,
            selectedPainAreaIDs: selectedPainAreas.map(\.rawValue).sorted(),
            problemAreaOtherText: problemAreaOtherText,
            activityLevel: activityLevel,
            lifestyle: lifestyle,
            selectedProblemTimes: selectedProblemTimes.sorted(),
            stretchingFrequency: stretchingFrequency,
            dailyTime: dailyTime,
            commitmentDays: commitmentDays,
            commitmentSignatureStrokes: commitmentSignatureStrokes,
            motivationLevel: motivationLevel
        )

        guard let data = try? JSONEncoder().encode(draft) else { return }
        userDefaults.set(data, forKey: Self.draftDefaultsKey)
    }

    private static func loadDraft(from userDefaults: UserDefaults) -> OnboardingDraft? {
        guard let data = userDefaults.data(forKey: draftDefaultsKey),
              let draft = try? JSONDecoder().decode(OnboardingDraft.self, from: data),
              draft.schemaVersion == draftSchemaVersion
        else {
            userDefaults.removeObject(forKey: draftDefaultsKey)
            return nil
        }
        return draft
    }
}

private struct OnboardingDraft: Codable {
    let schemaVersion: Int
    let stepID: String
    let userName: String
    let ageRange: String
    let selectedBodyGoals: [String]
    let longTermGoal: String
    let painFrequency: Int
    let painImpact: Int
    let selectedPainAreaIDs: [String]
    let problemAreaOtherText: String
    let activityLevel: String
    let lifestyle: String
    let selectedProblemTimes: [String]
    let stretchingFrequency: String
    let dailyTime: String
    let commitmentDays: String
    let commitmentSignatureStrokes: [[CGPoint]]
    let motivationLevel: String
}
