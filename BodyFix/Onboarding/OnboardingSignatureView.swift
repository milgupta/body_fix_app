import SwiftUI

struct OnboardingSignatureView: View {
    @Environment(OnboardingViewModel.self) private var viewModel

    private var commitmentFrequency: (value: String, suffix: String) {
        if viewModel.commitmentDays.caseInsensitiveCompare("Every day") == .orderedSame {
            return ("every day", "")
        }
        return (viewModel.commitmentDays, "per week")
    }

    private var formattedBodyAreas: String {
        var areas = OnboardingPainArea.allCases.compactMap { area -> String? in
            guard area != .other, viewModel.selectedPainAreas.contains(area) else { return nil }
            return area.displayName.lowercased()
        }

        if viewModel.selectedPainAreas.contains(.other) {
            let custom = viewModel.problemAreaOtherText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !custom.isEmpty {
                areas.append(custom.lowercased())
            }
        }

        switch areas.count {
        case 0:
            return "your body"
        case 1:
            return areas[0]
        case 2:
            return "\(areas[0]) & \(areas[1])"
        default:
            return areas.joined(separator: ", ")
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Make your commitment")
                        .font(Typography.question)
                        .foregroundStyle(.bfTextPrimary)

                    Text("From today forward, I choose to:")
                        .font(Typography.subtitle)
                        .foregroundStyle(.bfTextTertiary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 18) {
                        CommitmentBulletRow {
                            CommitmentValueLine(
                                prefix: "Stretch for",
                                value: viewModel.dailyTime,
                                suffix: ""
                            )
                        }

                        CommitmentBulletRow {
                            CommitmentValueLine(
                                prefix: "Show up",
                                value: commitmentFrequency.value,
                                suffix: commitmentFrequency.suffix
                            )
                        }

                        CommitmentBulletRow {
                            CommitmentValueLine(
                                prefix: "Work on my",
                                value: formattedBodyAreas,
                                suffix: ""
                            )
                        }

                        CommitmentBulletRow {
                            Text("Never push through sharp pain")
                                .font(Typography.optionText)
                                .foregroundStyle(.bfTextPrimary)
                        }
                    }
                    .padding(.top, 26)

                    HStack {
                        Text("SIGN HERE")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.bfTextMuted)

                        Spacer()

                        Button {
                            HapticManager.shared.softImpact()
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.commitmentSignatureStrokes.removeAll()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.bfMint)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.bfSurfaceElevated))
                                .overlay(Circle().stroke(Color.bfBorder, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.commitmentSignatureStrokes.isEmpty)
                        .opacity(viewModel.commitmentSignatureStrokes.isEmpty ? 0.45 : 1)
                        .accessibilityLabel("Clear signature")
                    }
                    .padding(.top, 34)

                    SignatureCanvas(strokes: $vm.commitmentSignatureStrokes)
                        .frame(height: 210)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.035), radius: 14, y: 6)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.bfBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .padding(.top, 10)

                    Text("Sign as a reminder of the promise you're making.")
                        .font(Typography.caption)
                        .foregroundStyle(.bfTextTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 14)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)

            OnboardingContinueButton(
                label: "Make my commitment",
                style: .gradientPrimary,
                isEnabled: viewModel.canAdvance,
                feedback: .success
            ) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    viewModel.advance()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
            .background(Color.bfPageBackground)
        }
    }
}

private struct CommitmentBulletRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(.bfProgressGradient)
                .frame(width: 8, height: 8)
                .padding(.top, 8)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct CommitmentValueLine: View {
    let prefix: String
    let value: String
    let suffix: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 7) {
                Text(prefix)
                    .fixedSize()
                valueChip(fixedWidth: true)
                if !suffix.isEmpty {
                    Text(suffix)
                        .fixedSize()
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(prefix)
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    valueChip(fixedWidth: false)
                    if !suffix.isEmpty {
                        Text(suffix)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }
        }
        .font(Typography.optionText)
        .foregroundStyle(.bfTextPrimary)
    }

    private func valueChip(fixedWidth: Bool) -> some View {
        Text(value)
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(Color.bfMint)
            .lineLimit(2)
            .fixedSize(horizontal: fixedWidth, vertical: true)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.bfAccent.opacity(0.12))
            )
    }
}

private struct SignatureCanvas: View {
    @Binding var strokes: [[CGPoint]]
    @State private var activeStroke: [CGPoint] = []

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, _ in
                for stroke in strokes {
                    draw(stroke, in: &context)
                }
                draw(activeStroke, in: &context)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let point = clamped(value.location, to: proxy.size)
                        if activeStroke.isEmpty {
                            activeStroke = [clamped(value.startLocation, to: proxy.size)]
                        }
                        if let last = activeStroke.last, distance(from: last, to: point) >= 1.5 {
                            activeStroke.append(point)
                        }
                    }
                    .onEnded { _ in
                        if pathLength(activeStroke) >= 12 {
                            strokes.append(activeStroke)
                            HapticManager.shared.selection()
                        }
                        activeStroke.removeAll(keepingCapacity: true)
                    }
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Signature area")
        .accessibilityValue(strokes.isEmpty ? "Empty" : "Signed")
        .accessibilityHint("Draw your signature with one finger")
    }

    private func draw(_ points: [CGPoint], in context: inout GraphicsContext) {
        guard points.count > 1 else { return }
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(
            path,
            with: .color(.bfTextPrimary),
            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
        )
    }

    private func clamped(_ point: CGPoint, to size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 2), max(2, size.width - 2)),
            y: min(max(point.y, 2), max(2, size.height - 2))
        )
    }

    private func pathLength(_ points: [CGPoint]) -> CGFloat {
        zip(points, points.dropFirst()).reduce(0) { partial, pair in
            partial + distance(from: pair.0, to: pair.1)
        }
    }

    private func distance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        hypot(end.x - start.x, end.y - start.y)
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    viewModel.currentStep = 17
    viewModel.dailyTime = "5 minutes"
    viewModel.commitmentDays = "3 days"
    viewModel.selectedPainAreas = [.neck, .upperBack, .hips]

    return ZStack {
        Color.bfPageBackground.ignoresSafeArea()
        OnboardingSignatureView()
    }
    .environment(viewModel)
}
