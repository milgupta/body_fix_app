import SwiftUI

struct OnboardingAnalyzingView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var analysisStep = 0
    @State private var showSilhouette = false

    private let steps = [
        "Analyzing posture habits",
        "Mapping tight areas",
        "Building stretch plan",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            BodySilhouetteView(
                highlightedRegions: showSilhouette ? viewModel.selectedPainAreas : [],
                tintColor: .white
            )
            .frame(width: 140, height: 350)
            .opacity(showSilhouette ? 1.0 : 0.3)

            Spacer().frame(height: 32)

            Text("Analyzing your body profile…")
                .font(Typography.splashTitle)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer().frame(height: 32)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 12) {
                        if index < analysisStep {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                        } else if index == analysisStep {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        Text(step)
                            .font(Typography.optionText)
                            .foregroundStyle(index <= analysisStep ? .white : .white.opacity(0.4))
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            runAnalysis()
        }
    }

    private func runAnalysis() {
        withAnimation(.easeOut(duration: 0.5)) {
            showSilhouette = true
        }

        for i in 0..<steps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.5 + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    analysisStep = i + 1
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            HapticManager.shared.success()
            withAnimation(.easeInOut(duration: 0.35)) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingAnalyzingView()
    }
    .environment(OnboardingViewModel())
}
