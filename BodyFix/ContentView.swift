import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @State private var paywallManager = PaywallManager.shared

    private var onboardingComplete: Bool {
        profiles.first?.onboardingComplete ?? false
    }

    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingContainerView()
            } else if paywallManager.isSubscribed {
                MainTabView()
            } else {
                LockedUnlockView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self, RoutineSeriesProgress.self, SavedRoutine.self, StretchTimingOverride.self], inMemory: true)
}
