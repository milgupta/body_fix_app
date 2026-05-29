import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage(PaywallManager.subscriptionKey) private var isSubscribed = false
    @AppStorage("show_reminder_prompt_after_subscription") private var showReminderPromptAfterSubscription = false
    @State private var showReminderPrompt = false
    @State private var showReminderSetup = false

    private var onboardingComplete: Bool {
        profiles.first?.onboardingComplete ?? false
    }

    var body: some View {
        Group {
            if onboardingComplete {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        .onAppear {
            if isSubscribed, showReminderPromptAfterSubscription {
                showReminderPrompt = true
            }
        }
        .onChange(of: isSubscribed) { _, newValue in
            if newValue, showReminderPromptAfterSubscription {
                showReminderPrompt = true
            }
        }
        .fullScreenCover(isPresented: $showReminderPrompt) {
            ReminderSoftPromptView {
                showReminderPrompt = false
                showReminderSetup = true
            } onNotNow: {
                showReminderPrompt = false
                showReminderPromptAfterSubscription = false
            }
        }
        .sheet(isPresented: $showReminderSetup) {
            ReminderSetupView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self, RoutineSeriesProgress.self, SavedRoutine.self, StretchTimingOverride.self], inMemory: true)
}
