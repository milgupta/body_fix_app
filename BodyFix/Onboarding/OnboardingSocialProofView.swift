import SwiftUI

struct OnboardingSocialProofView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private let reviews = [
        Review(
            title: "So helpful",
            body: "This is the app I didn't know I needed! Hairstylist of over 14 years and my posture, back and neck have suffered for too long. Where has this been?!"
        ),
        Review(
            title: "Amazing",
            body: "Super easy to use, have me a personalized routine for my back issues, and even has super specific routines (I like the tech neck one). Highly recommend!"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("People are already feeling **better**.")
                            .font(Typography.question)
                            .foregroundStyle(.bfTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Real feedback from Body Fix users.")
                            .font(Typography.subtitle)
                            .foregroundStyle(.bfTextSecondary)
                    }

                    ratingSummary

                    VStack(spacing: 14) {
                        ForEach(reviews) { review in
                            reviewCard(review)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            OnboardingContinueButton {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private var ratingSummary: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.bfAccentWarm.opacity(0.22),
                    Color.bfSliderWarm.opacity(0.07),
                    .clear,
                ],
                center: .center,
                startRadius: 0,
                endRadius: 135
            )

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    RatingLaurel()

                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 17, style: .continuous)
                                .stroke(Color.white.opacity(0.8), lineWidth: 1)
                        )
                        .shadow(color: Color.bfHeroSurface.opacity(0.14), radius: 12, y: 6)
                        .accessibilityLabel("Body Fix")

                    RatingLaurel()
                        .scaleEffect(x: -1)
                }

                HStack(spacing: 5) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.bfSliderWarm)
                    }
                }
                .accessibilityHidden(true)

                Text("5.0 on the App Store")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.bfTextSecondary)
            }
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Body Fix. Five out of five stars on the App Store")
    }

    private func reviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.bfSliderWarm)
                }
            }
            .accessibilityHidden(true)

            Text(review.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.bfTextPrimary)

            Text(review.body)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.bfBorder.opacity(0.72), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 16, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Five star review, \(review.title). \(review.body)")
    }
}

private struct RatingLaurel: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.bfSliderWarm.opacity(0.72))
                .frame(width: 2, height: 50)
                .rotationEffect(.degrees(-17))
                .offset(x: 6)

            laurelLeaf(rotation: -48, x: -2, y: 17)
            laurelLeaf(rotation: -31, x: 1, y: 5)
            laurelLeaf(rotation: -13, x: 5, y: -8)
            laurelLeaf(rotation: 8, x: 10, y: -20)

            laurelLeaf(rotation: 48, x: 14, y: 13)
            laurelLeaf(rotation: 31, x: 16, y: 0)
            laurelLeaf(rotation: 13, x: 17, y: -14)
        }
        .frame(width: 36, height: 64)
        .accessibilityHidden(true)
    }

    private func laurelLeaf(rotation: Double, x: CGFloat, y: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.bfSliderWarm,
                        Color.bfAccentWarm,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 9, height: 17)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
}

private extension OnboardingSocialProofView {
    struct Review: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }
}

#Preview {
    ZStack {
        Color.bfPageBackground.ignoresSafeArea()
        OnboardingSocialProofView()
    }
    .environment(OnboardingViewModel())
}
