import SwiftUI

struct OnboardingBuildProgramView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @State private var showContent = false

    private var previewRoutine: Routine? {
        let preferredIds = ["posture_reset", "desk_relief", "lower_back_quick", "hip_opener"]
        let routines = StretchDatabase.loadAllRoutines()
        return preferredIds.compactMap { id in
            routines.first { $0.id == id }
        }.first
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

            VStack(spacing: 20) {
                routinePreviewCard
                programCard
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 12) {
                Text("We're shaping your first routine.")
                    .font(Typography.splashTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)

                Text("A few more answers and you'll see a plan that feels personal, simple, and realistic to stick with.")
                    .font(Typography.subtitle)
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 24)

            OnboardingContinueButton(label: "Build My Program") {
                HapticManager.shared.mediumImpact()
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

    private var routinePreviewCard: some View {
        HStack(alignment: .center, spacing: 16) {
            BodyFixThumbnailView(routine: previewRoutine, size: 64, isFeatured: false)

            VStack(alignment: .leading, spacing: 6) {
                Text(previewRoutine?.name ?? "Your first routine")
                    .font(Typography.optionText)
                    .foregroundStyle(.bfTextPrimary)

                Text("Built around your goals, tight spots, and the time you actually have.")
                    .font(Typography.caption)
                    .foregroundStyle(.bfTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        )
    }

    private var programCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("What your plan includes")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.bfTextPrimary)

                Spacer()
            }

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
                            .foregroundStyle(.bfTextPrimary)

                        Text(row.detail)
                            .font(Typography.caption)
                            .foregroundStyle(.bfTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 16, y: 8)
        )
    }

    private var programRows: [(icon: String, title: String, detail: String, tint: Color)] {
        [
            ("🧭", "A routine matched to your goals", "We'll focus on what matters most to you first.", .blue),
            ("🧘", "Targeted stretches for your tight spots", "Expect movements chosen for the areas you flagged.", .green),
            ("🔁", "A plan you can actually repeat", "Short sessions that feel realistic to keep up with.", .orange),
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
