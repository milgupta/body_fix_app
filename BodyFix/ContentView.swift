import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    private var onboardingComplete: Bool {
        profiles.first?.onboardingComplete ?? false
    }

    var body: some View {
        if onboardingComplete {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, StretchSession.self], inMemory: true)
}
