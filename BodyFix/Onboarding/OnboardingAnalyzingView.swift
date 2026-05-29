import SwiftUI

struct OnboardingAnalyzingView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var analysisStep = 0
    @State private var revealedCards: Set<Int> = []
    @State private var isCancelled = false
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
                    .scaleEffect(completedStepPop.contains(index) ? 1.22 : 1.0)

                Circle()
                    .stroke(Color.green.opacity(completedStepPop.contains(index) ? 0.36 : 0), lineWidth: 1.5)
                    .frame(width: 24, height: 24)
                    .scaleEffect(completedStepPop.contains(index) ? 1.55 : 0.85)
                    .opacity(completedStepPop.contains(index) ? 1 : 0)

                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.green.opacity(0.95))
            }
            .scaleEffect(completedStepPop.contains(index) ? 1.16 : 1.0)
            .animation(.spring(response: 0.34, dampingFraction: 0.58), value: completedStepPop)
        } else if index == analysisStep {
            ActiveStepSpinner()
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
                _ = revealedCards.insert(index)
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

private struct ActiveStepSpinner: View {
    @State private var isSpinning = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 26, height: 26)

            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                .frame(width: 17, height: 17)

            Circle()
                .trim(from: 0.08, to: 0.68)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.28),
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.9, lineCap: .round)
                )
                .frame(width: 17, height: 17)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))

            Circle()
                .fill(Color.white)
                .frame(width: 4.5, height: 4.5)
                .offset(y: -8.5)
                .rotationEffect(.degrees(isSpinning ? -360 : 0))
                .shadow(color: Color.white.opacity(0.35), radius: 2)

            Circle()
                .fill(Color.white)
                .frame(width: 5.5, height: 5.5)
        }
        .onAppear {
            isSpinning = false
            withAnimation(.linear(duration: 0.95).repeatForever(autoreverses: false)) {
                isSpinning = true
            }
        }
    }
}

private struct AnalysisCardStack: View {
    let routines: [Routine]
    let activeStep: Int
    let revealedCards: Set<Int>

    private let foregroundCardWidth: CGFloat = 220
    private let foregroundCardPadding: CGFloat = 20

    private var leadRoutine: Routine? { routines.first }
    private var supportRoutine: Routine? { routines.dropFirst().first }
    private var recoveryRoutine: Routine? { routines.dropFirst(2).first }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 250, height: 250)
                .blur(radius: 26)

            backgroundCard(
                eyebrow: "FOCUS AREAS",
                title: "Posture + Desk Relief",
                subtitle: "Targeting the spots that tighten up first.",
                routines: [leadRoutine, supportRoutine].compactMap { $0 },
                cardSize: CGSize(width: 196, height: 144),
                finalOffset: CGSize(width: -30, height: -2),
                foldedOffset: CGSize(width: -4, height: 14),
                foldedRotation: -2,
                finalRotation: -13,
                opacity: 0.36,
                revealIndex: 1
            )

            backgroundCard(
                eyebrow: "DAILY FIT",
                title: "Quick sessions",
                subtitle: "Built to feel realistic on busy days.",
                routines: [supportRoutine, recoveryRoutine].compactMap { $0 },
                cardSize: CGSize(width: 204, height: 148),
                finalOffset: CGSize(width: 28, height: -10),
                foldedOffset: CGSize(width: 4, height: 8),
                foldedRotation: 2,
                finalRotation: 11,
                opacity: 0.3,
                revealIndex: 2
            )

            foregroundCard
                .opacity(revealedCards.contains(3) ? 1 : 0)
                .offset(
                    x: revealedCards.contains(3) ? 0 : 2,
                    y: revealedCards.contains(3) ? 0 : 18
                )
                .rotationEffect(.degrees(revealedCards.contains(3) ? 0 : 2))
                .scaleEffect(revealedCards.contains(3) ? 1 : 0.94)
        }
    }

    private func backgroundCard(
        eyebrow: String,
        title: String,
        subtitle: String,
        routines: [Routine],
        cardSize: CGSize,
        finalOffset: CGSize,
        foldedOffset: CGSize,
        foldedRotation: Double,
        finalRotation: Double,
        opacity: Double,
        revealIndex: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(Typography.timerLabelSmall)
                .foregroundStyle(Color.white.opacity(0.7))

            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            Text(subtitle)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(2)

            HStack(spacing: 8) {
                ForEach(routines.prefix(3), id: \.id) { routine in
                    BodyFixThumbnailView(routine: routine, size: 32, isFeatured: true)
                }
            }
            .padding(.top, 2)
        }
        .padding(16)
        .frame(width: cardSize.width, height: cardSize.height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(opacity + (activeStep >= revealIndex ? 0.05 : 0)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 6)
        .rotationEffect(.degrees(revealedCards.contains(revealIndex) ? finalRotation : foldedRotation))
        .offset(
            x: revealedCards.contains(revealIndex) ? finalOffset.width : foldedOffset.width,
            y: revealedCards.contains(revealIndex) ? finalOffset.height : foldedOffset.height
        )
        .opacity(revealedCards.contains(revealIndex) ? 1 : 0)
        .scaleEffect(revealedCards.contains(revealIndex) ? 1 : 0.9)
        .animation(.spring(response: 0.56, dampingFraction: 0.8), value: revealedCards)
        .animation(.easeInOut(duration: 0.32), value: activeStep)
    }

    private var foregroundCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let leadRoutine {
                Text(StretchDatabase.durationLabel(for: leadRoutine))
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
                .frame(width: foregroundCardWidth - foregroundCardPadding * 2, alignment: .center)
                .padding(.top, 2)
            }
        }
        .padding(foregroundCardPadding)
        .frame(width: foregroundCardWidth, height: 170, alignment: .topLeading)
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
