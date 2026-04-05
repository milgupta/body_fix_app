import SwiftUI

struct OnboardingAnalyzingView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var analysisStep = 0
    @State private var revealedCards = 0
    @State private var isCancelled = false
    @State private var pulseCurrentStep = false
    @State private var completedStepPop: Set<Int> = []

    private let steps = [
        "Noticing your tight spots",
        "Matching your daily routine",
        "Shaping your first stretch plan",
    ]

    private var previewRoutines: [Routine] {
        [
            "posture_reset",
            "desk_relief",
            "hip_opener",
        ].compactMap { StretchDatabase.routine(id: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    HapticManager.shared.softImpact()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.navIcon)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)

            Spacer(minLength: 0)

            AnalysisCardStack(
                routines: previewRoutines,
                activeStep: analysisStep,
                revealedCards: revealedCards
            )
            .frame(width: 260, height: 260)

            Spacer().frame(height: 34)

            Text("Getting your plan ready")
                .font(Typography.splashTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 14)

            Text("A few final touches, then your first Body Fix routine is ready.")
                .font(Typography.subtitle)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 34)

            Spacer().frame(height: 32)

            VStack(alignment: .leading, spacing: 18) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        stepIndicator(for: index)

                        Text(step)
                            .font(Typography.optionText)
                            .foregroundStyle(index <= analysisStep ? .white : .white.opacity(0.45))
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            isCancelled = false
            pulseCurrentStep = true
            runAnalysis()
        }
        .onDisappear {
            isCancelled = true
        }
    }

    @ViewBuilder
    private func stepIndicator(for index: Int) -> some View {
        if index < analysisStep {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.24))
                    .frame(width: 24, height: 24)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.green.opacity(0.95))
            }
            .scaleEffect(completedStepPop.contains(index) ? 1.16 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.58), value: completedStepPop)
        } else if index == analysisStep {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 24, height: 24)

                Circle()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
                    .scaleEffect(pulseCurrentStep ? 1.22 : 0.92)
                    .opacity(pulseCurrentStep ? 0.35 : 0.12)

                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseCurrentStep ? 1.12 : 0.84)
                    .opacity(pulseCurrentStep ? 1 : 0.7)
            }
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulseCurrentStep)
        } else {
            Circle()
                .fill(Color.white.opacity(0.22))
                .frame(width: 10, height: 10)
                .padding(.horizontal, 7)
        }
    }

    private func runAnalysis() {
        revealCard(index: 1, after: 0.05)
        revealCard(index: 2, after: 0.24)
        revealCard(index: 3, after: 0.43)

        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.35 + 0.7) {
                guard !isCancelled else { return }
                HapticManager.shared.selection()
                withAnimation(.easeInOut(duration: 0.28)) {
                    analysisStep = i + 1
                }
                popCompletedStep(i)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
            guard !isCancelled else { return }
            HapticManager.shared.success()
            withAnimation(.easeInOut(duration: 0.35)) {
                viewModel.advance()
            }
        }
    }

    private func revealCard(index: Int, after delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard !isCancelled else { return }
            withAnimation(.spring(response: 0.52, dampingFraction: 0.84)) {
                revealedCards = max(revealedCards, index)
            }
        }
    }

    private func popCompletedStep(_ index: Int) {
        completedStepPop.insert(index)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            completedStepPop.remove(index)
        }
    }
}

private struct AnalysisCardStack: View {
    let routines: [Routine]
    let activeStep: Int
    let revealedCards: Int

    private var leadRoutine: Routine? { routines.first }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 26)

            backgroundCard(
                title: "DAILY FLOW",
                offset: CGSize(width: -14, height: -14),
                rotation: -6,
                opacity: 0.26,
                revealIndex: 1
            )

            backgroundCard(
                title: "RELIEF AREAS",
                offset: CGSize(width: 16, height: -2),
                rotation: 5,
                opacity: 0.2,
                revealIndex: 2
            )

            foregroundCard
                .opacity(revealedCards >= 3 ? 1 : 0)
                .offset(y: revealedCards >= 3 ? 0 : 22)
                .scaleEffect(revealedCards >= 3 ? 1 : 0.94)
        }
    }

    private func backgroundCard(
        title: String,
        offset: CGSize,
        rotation: Double,
        opacity: Double,
        revealIndex: Int
    ) -> some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color.white.opacity(opacity + (activeStep >= revealIndex ? 0.06 : 0)))
            .frame(width: 196, height: 138)
            .overlay(alignment: .topLeading) {
                Text(title)
                    .font(Typography.timerLabelSmall)
                    .foregroundStyle(Color.white.opacity(0.72))
                    .padding(.top, 16)
                    .padding(.leading, 16)
            }
            .overlay {
                VStack(spacing: 10) {
                    Capsule()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: 92, height: 10)
                    HStack(spacing: 8) {
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 28, height: 28)
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 28, height: 28)
                        Circle().fill(Color.white.opacity(0.18)).frame(width: 28, height: 28)
                    }
                }
            }
            .rotationEffect(.degrees(rotation))
            .offset(
                x: offset.width,
                y: (revealedCards >= revealIndex ? offset.height : offset.height + 24)
            )
            .opacity(revealedCards >= revealIndex ? 1 : 0)
            .scaleEffect(revealedCards >= revealIndex ? 1 : 0.96)
            .animation(.spring(response: 0.52, dampingFraction: 0.84), value: revealedCards)
            .animation(.easeInOut(duration: 0.32), value: activeStep)
    }

    private var foregroundCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let leadRoutine {
                Text(leadRoutine.durationLabel)
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.white.opacity(0.82))

                Text("Your first routine")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.72))

                Text(leadRoutine.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("A simple reset built around what your body needs most right now.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineLimit(2)

                HStack(spacing: 10) {
                    ForEach(routines.prefix(3), id: \.id) { routine in
                        BodyFixThumbnailView(routine: routine, size: 42, isFeatured: true)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 220, height: 170, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(LinearGradient.bfHeroGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
        .animation(.spring(response: 0.52, dampingFraction: 0.84), value: revealedCards)
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingAnalyzingView()
    }
    .environment(OnboardingViewModel())
}
