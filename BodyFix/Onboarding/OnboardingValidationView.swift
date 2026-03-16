import SwiftUI

struct OnboardingValidationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    private static let goalDescriptions: [String: String] = [
        "Reduce Pain & Stiffness": "We'll target the areas holding you back.",
        "Improve Flexibility": "Unlock your body's full range of motion.",
        "Better Posture": "Realign and stand taller, naturally.",
        "Recover Faster from Workouts": "Speed up recovery with targeted stretches.",
        "Reduce Stress & Tension": "Release the tension your body carries.",
        "Improve Sleep Quality": "Relax tight muscles before bed.",
        "Move Better Day-to-Day": "Feel lighter and more fluid in everything you do.",
    ]

    private static let goalEmojis: [String: String] = [
        "Reduce Pain & Stiffness": "🩹",
        "Improve Flexibility": "🧘",
        "Better Posture": "🧍",
        "Recover Faster from Workouts": "🔄",
        "Reduce Stress & Tension": "😌",
        "Improve Sleep Quality": "💤",
        "Move Better Day-to-Day": "🚶",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 20) {
                ForEach(Array(viewModel.selectedBodyGoals.enumerated()), id: \.element) { index, goal in
                    goalCard(
                        emoji: Self.goalEmojis[goal] ?? "",
                        title: goal,
                        description: Self.goalDescriptions[goal] ?? ""
                    )
                    .rotationEffect(.degrees(Double([-4, 3, -3][index % 3])))
                    .offset(x: CGFloat([-8, 10, -4][index % 3]))
                    .opacity(showContent ? 1.0 : 0)
                }

                if !viewModel.longTermGoal.isEmpty {
                    longTermCard
                        .rotationEffect(.degrees(4))
                        .offset(x: 6)
                        .opacity(showContent ? 1.0 : 0)
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 32)

            VStack(spacing: 12) {
                Text("You're in the right place!")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("**Thousands** have started with the same goals, and **Body Fix** got them there.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .opacity(showContent ? 1.0 : 0)

            Spacer(minLength: 24)

            OnboardingContinueButton(label: "Find My Fix") {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private func goalCard(emoji: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.optionText)
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bfCardDark.opacity(0.85))
        )
    }

    private var longTermCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where You're Headed")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.bfTeal)

            Text(viewModel.longTermGoal)
                .font(Typography.optionText)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bfCardDark.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bfTeal.opacity(0.4), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingValidationView()
    }
    .environment(OnboardingViewModel())
}
