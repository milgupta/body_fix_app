import SwiftUI

struct CircularTimerView: View {
    let totalSeconds: Int
    let remainingSeconds: Int
    var isComplete: Bool
    var isRunning: Bool
    var diameter: CGFloat = 232
    var lineWidth: CGFloat = 12

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }

    private var ringColor: Color {
        if isComplete { return Color.bfMint }
        return isRunning ? Color.bfBlue : Color.bfBlue.opacity(0.6)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: diameter, height: diameter)
                .shadow(color: Color.black.opacity(0.035), radius: 18, y: 8)

            Circle()
                .stroke(Color.bfSurfaceMuted, lineWidth: lineWidth)
                .frame(width: diameter, height: diameter)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
                .animation(.easeInOut(duration: 0.35), value: isComplete)

            VStack(spacing: 4) {
                Text("\(max(0, remainingSeconds))")
                    .font(Typography.timerMonoLarge)
                    .foregroundStyle(Color.bfTextPrimary)
                    .contentTransition(.numericText())

                Text(isComplete ? "DONE!" : "SECONDS")
                    .font(Typography.timerLabelSmall)
                    .foregroundStyle(isComplete ? Color.bfMint : Color.bfTextMuted)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

#Preview {
    ZStack {
        Color.bfBackground.ignoresSafeArea()
        CircularTimerView(totalSeconds: 30, remainingSeconds: 12, isComplete: false, isRunning: true)
    }
}
