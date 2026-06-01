import SwiftUI

struct OnboardingValidationView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    private static let goalDescriptions: [String: String] = [
        "Reduce pain and stiffness": "We'll focus on the areas that keep slowing you down.",
        "Improve Flexibility": "Unlock your body's full range of motion.",
        "Improve posture": "Build better alignment and feel more supported all day.",
        "Recover faster from workouts": "Bounce back with targeted recovery work.",
        "Reduce stress and tension": "Ease the tightness your body carries through the day.",
        "Sleep better": "Wind down with movements that help your body let go.",
        "Move better day to day": "Feel lighter, looser, and more comfortable in everyday life.",
    ]

    private static let goalEmojis: [String: String] = [
        "Reduce pain and stiffness": "🩹",
        "Improve Flexibility": "🧘",
        "Improve posture": "🧍",
        "Recover faster from workouts": "🔄",
        "Reduce stress and tension": "😌",
        "Sleep better": "💤",
        "Move better day to day": "🚶",
    ]

    private var totalCardCount: Int {
        viewModel.selectedBodyGoals.count + (viewModel.longTermGoal.isEmpty ? 0 : 1)
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
            cardStack
            Spacer(minLength: 20)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We hear what matters most.")
                        .font(Typography.splashTitle)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)

                    Text("Your plan will focus on the goals you picked, without wasting time on things that do not fit your body or routine.")
                        .font(Typography.subtitle)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

                Spacer().frame(height: 20)

                OnboardingContinueButton(label: "Find My Fix", feedback: .medium) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.advance()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .opacity(showContent ? 1.0 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private var cardStack: some View {
        VStack(spacing: 18) {
            ForEach(Array(viewModel.selectedBodyGoals.enumerated()), id: \.element) { index, goal in
                goalCard(
                    emoji: Self.goalEmojis[goal] ?? "",
                    title: goal,
                    description: Self.goalDescriptions[goal] ?? ""
                )
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 16)
                .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.08), value: showContent)
            }

            if !viewModel.longTermGoal.isEmpty {
                longTermCard
                    .opacity(showContent ? 1.0 : 0)
                    .offset(y: showContent ? 0 : 16)
                    .animation(.easeOut(duration: 0.45).delay(Double(viewModel.selectedBodyGoals.count) * 0.08), value: showContent)
            }
        }
        .padding(.horizontal, 20)
    }

    private func goalCard(emoji: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(emoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Typography.optionText)
                    .foregroundStyle(.bfTextPrimary)

                Text(description)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(.bfTextSecondary)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bfBorder.opacity(0.75), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 8)
    }

    private var longTermCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Long-Term Focus")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.bfAccent)

            Text(viewModel.longTermGoal)
                .font(Typography.optionText)
                .foregroundStyle(.bfTextPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.bfAccent.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 16, x: 0, y: 7)
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingValidationView()
    }
    .environment(OnboardingViewModel())
}
