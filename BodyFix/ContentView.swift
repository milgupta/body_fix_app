import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @State private var paywallManager = PaywallManager.shared
    @State private var showsLaunchLoading = true

    private var onboardingComplete: Bool {
        profiles.first?.onboardingComplete ?? false
    }

    var body: some View {
        ZStack {
            Group {
                if !onboardingComplete {
                    OnboardingContainerView()
                } else if paywallManager.isSubscribed {
                    MainTabView()
                } else {
                    LockedUnlockView()
                }
            }

            if showsLaunchLoading {
                LaunchLoadingView {
                    showsLaunchLoading = false
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }
}

private struct LaunchLoadingView: View {
    let onFinished: () -> Void

    @State private var showsLogo = false
    @State private var showsDots = false
    @State private var fadesOut = false
    @State private var logoPulse = false

    var body: some View {
        ZStack {
            Color.bfBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 1)
                    )
                    .shadow(color: Color.bfHeroSurface.opacity(0.16), radius: 22, y: 12)
                    .scaleEffect(logoPulse ? 1.04 : (showsLogo ? 1 : 0.86))
                    .opacity(showsLogo ? 1 : 0)
                    .animation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true), value: logoPulse)
                .offset(y: -50)

                Spacer(minLength: 0)

                LaunchLoadingDots()
                    .opacity(showsDots ? 1 : 0)
                    .offset(y: -76)
            }
        }
        .opacity(fadesOut ? 0 : 1)
        .task {
            await runAnimation()
        }
    }

    private func runAnimation() async {
        await MainActor.run {
            withAnimation(.spring(response: 0.58, dampingFraction: 0.72)) {
                showsLogo = true
            }
        }

        try? await Task.sleep(nanoseconds: 520_000_000)
        await MainActor.run {
            logoPulse = true
        }

        try? await Task.sleep(nanoseconds: 480_000_000)
        await MainActor.run {
            withAnimation(.easeOut(duration: 0.28)) {
                showsDots = true
            }
        }

        try? await Task.sleep(nanoseconds: 2_250_000_000)
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.42)) {
                fadesOut = true
            }
        }

        try? await Task.sleep(nanoseconds: 440_000_000)
        await MainActor.run {
            onFinished()
        }
    }
}

private struct LaunchLoadingDots: View {
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 10

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = Int((timeline.date.timeIntervalSinceReferenceDate * 3).rounded(.down)) % 3

            HStack(spacing: dotSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == phase ? Color.bfMint : Color.bfBorder)
                        .frame(width: dotSize, height: dotSize)
                        .opacity(index == phase ? 0.92 : 0.72)
                        .scaleEffect(index == phase ? 1.22 : 1.0)
                        .animation(.easeInOut(duration: 0.22), value: phase)
                }
            }
            .accessibilityHidden(true)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProfile.self, PersonalizedPlan.self, StretchSession.self, RoutineSeriesProgress.self, SavedRoutine.self, StretchTimingOverride.self], inMemory: true)
}
