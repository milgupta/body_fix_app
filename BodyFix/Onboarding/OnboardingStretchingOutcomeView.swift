import SwiftUI

struct OnboardingStretchingOutcomeView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showCard = false
    @State private var consistentLineProgress: CGFloat = 0
    @State private var skippedLineProgress: CGFloat = 0
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("Stretching works when you keep showing up.")
                            .font(Typography.question)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.82)

                        Text("Even a few minutes at a time can build toward less stiffness and easier movement.")
                            .font(Typography.caption)
                            .foregroundStyle(.white.opacity(0.82))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 4)

                    outcomeGraph
                        .opacity(showCard ? 1 : 0)
                        .scaleEffect(showCard ? 1 : 0.96)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
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
        .onAppear(perform: startAnimation)
    }

    private var outcomeGraph: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How your body feels over time")
                .font(Typography.cardTitle)
                .foregroundStyle(.bfTextPrimary)

            HStack(spacing: 16) {
                legend(color: .bfSliderGreen, title: "Stretching consistently")
                legend(color: .bfSliderWarm, title: "Skipping stretches")
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack {
                    graphGrid

                    StretchingOutcomeAreaShape()
                        .fill(
                            LinearGradient(
                                colors: [Color.bfSliderGreen.opacity(0.20), Color.bfSliderGreen.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .opacity(showDetails ? 1 : 0)

                    SkippedStretchingShape()
                        .trim(from: 0, to: skippedLineProgress)
                        .stroke(
                            Color.bfSliderWarm,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )

                    StretchingOutcomeShape()
                        .trim(from: 0, to: consistentLineProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.bfBlue, .bfSliderGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )

                    Path { path in
                        path.move(to: CGPoint(x: width * 0.95, y: height * 0.12))
                        path.addLine(to: CGPoint(x: width * 0.90, y: height * 0.07))
                    }
                    .stroke(
                        Color.bfSliderGreen.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .opacity(showDetails ? 1 : 0)

                    Path { path in
                        path.move(to: CGPoint(x: width * 0.95, y: height * 0.78))
                        path.addLine(to: CGPoint(x: width * 0.90, y: height * 0.82))
                    }
                    .stroke(
                        Color.bfSliderWarm.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                    )
                    .opacity(showDetails ? 1 : 0)

                    endpointMarker(color: .bfSliderGreen)
                        .position(x: width * 0.95, y: height * 0.12)

                    endpointMarker(color: .bfSliderWarm)
                        .position(x: width * 0.95, y: height * 0.78)

                    endpointCallout(
                        title: "Moving easier",
                        color: .bfSliderGreen,
                        systemImage: "arrow.up.right"
                    )
                    .position(x: width * 0.70, y: height * 0.07)

                    endpointCallout(
                        title: "Still tight",
                        color: .bfSliderWarm,
                        systemImage: "arrow.right"
                    )
                    .position(x: width * 0.73, y: height * 0.82)

                    HStack {
                        Text("Week 1")
                        Spacer()
                        Text("Week 2")
                        Spacer()
                        Text("Week 3")
                    }
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.bfTextTertiary)
                    .padding(.horizontal, width * 0.03)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 210)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Over three weeks, the stretching consistently line rises toward moving easier, while the skipping stretches line remains near still tight.")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.72), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.14), radius: 22, y: 12)
    }

    private var graphGrid: some View {
        VStack {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(Color.bfBorder.opacity(0.55))
                    .frame(height: 1)
                Spacer()
            }
            Rectangle()
                .fill(Color.bfTextTertiary.opacity(0.65))
                .frame(height: 1)
                .padding(.bottom, 22)
        }
    }

    private func legend(color: Color, title: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(color)
                .frame(width: 18, height: 4)

            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.bfTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func endpointCallout(title: String, color: Color, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.bfTextPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.bfSurfaceElevated.opacity(0.98))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.34), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
        )
        .opacity(showDetails ? 1 : 0)
        .scaleEffect(showDetails ? 1 : 0.85)
    }

    private func endpointMarker(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.bfSurfaceElevated, lineWidth: 2)
            )
            .shadow(color: color.opacity(0.24), radius: 4, y: 2)
            .opacity(showDetails ? 1 : 0)
            .scaleEffect(showDetails ? 1 : 0.6)
    }

    private func startAnimation() {
        showCard = false
        consistentLineProgress = 0
        skippedLineProgress = 0
        showDetails = false

        guard !reduceMotion else {
            showCard = true
            consistentLineProgress = 1
            skippedLineProgress = 1
            showDetails = true
            return
        }

        withAnimation(.easeOut(duration: 0.45)) {
            showCard = true
        }
        withAnimation(.easeInOut(duration: 1.25).delay(0.25)) {
            consistentLineProgress = 1
        }
        withAnimation(.easeInOut(duration: 1.05).delay(0.45)) {
            skippedLineProgress = 1
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(1.35)) {
            showDetails = true
        }
    }
}

private struct StretchingOutcomeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(0.04, 0.78, in: rect))
        path.addCurve(
            to: point(0.34, 0.54, in: rect),
            control1: point(0.15, 0.78, in: rect),
            control2: point(0.20, 0.55, in: rect)
        )
        path.addCurve(
            to: point(0.60, 0.34, in: rect),
            control1: point(0.43, 0.53, in: rect),
            control2: point(0.49, 0.35, in: rect)
        )
        path.addCurve(
            to: point(0.95, 0.12, in: rect),
            control1: point(0.74, 0.33, in: rect),
            control2: point(0.86, 0.18, in: rect)
        )
        return path
    }
}

private struct StretchingOutcomeAreaShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = StretchingOutcomeShape().path(in: rect)
        path.addLine(to: point(0.95, 0.88, in: rect))
        path.addLine(to: point(0.04, 0.88, in: rect))
        path.closeSubpath()
        return path
    }
}

private struct SkippedStretchingShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: point(0.04, 0.76, in: rect))
        path.addCurve(
            to: point(0.30, 0.70, in: rect),
            control1: point(0.12, 0.76, in: rect),
            control2: point(0.18, 0.60, in: rect)
        )
        path.addCurve(
            to: point(0.50, 0.76, in: rect),
            control1: point(0.38, 0.80, in: rect),
            control2: point(0.43, 0.65, in: rect)
        )
        path.addCurve(
            to: point(0.70, 0.66, in: rect),
            control1: point(0.58, 0.84, in: rect),
            control2: point(0.62, 0.60, in: rect)
        )
        path.addCurve(
            to: point(0.95, 0.78, in: rect),
            control1: point(0.78, 0.74, in: rect),
            control2: point(0.86, 0.65, in: rect)
        )
        return path
    }
}

private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingStretchingOutcomeView()
    }
    .environment(OnboardingViewModel())
}
