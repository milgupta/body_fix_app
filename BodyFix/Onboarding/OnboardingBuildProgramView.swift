import SwiftUI

struct OnboardingBuildProgramView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

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

            VStack(spacing: 20) {
                bodyReportCard
                programCard
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 12) {
                Text("Let us build a **program** for you!")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text("Get **personalized stretches** and an **expert-backed program** designed to **unlock your body's potential**.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 32)

            OnboardingContinueButton(label: "Build My Program") {
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

    private var bodyReportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Body Report")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red.opacity(0.7))
                    Image(systemName: "figure.stand")
                        .foregroundStyle(.green.opacity(0.7))
                }
                .font(.system(size: 14))
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [.orange, .yellow, .green],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 10)

            HStack(spacing: 4) {
                Text("You vs Others")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.gray)
                Spacer()
            }

            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green.opacity(0.5))
                    .frame(width: 100, height: 8)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.green.opacity(0.25))
                    .frame(height: 8)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    private var programCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Program")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.black)

            ForEach(programRows, id: \.title) { row in
                HStack(spacing: 12) {
                    Text(row.icon)
                        .font(.system(size: 18))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(row.tint.opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 6)
                    }

                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }

    private var programRows: [(icon: String, title: String, tint: Color)] {
        [
            ("📋", "Day 0: Body Assessment", .blue),
            ("🧘", "Day 1: First Stretch Session", .green),
            ("🔥", "Day 2: Build the Habit", .orange),
        ]
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingBuildProgramView()
    }
    .environment(OnboardingViewModel())
}
