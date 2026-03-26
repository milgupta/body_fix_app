import SwiftUI

struct CircularTimerView: View {
    let totalSeconds: Int
    let remainingSeconds: Int
    var isComplete: Bool
    var isRunning: Bool

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
                .stroke(Color.bfCard, lineWidth: 8)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
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
        .frame(width: 200, height: 200)
    }
}

#Preview {
    ZStack {
        Color.bfBackground.ignoresSafeArea()
        CircularTimerView(totalSeconds: 30, remainingSeconds: 12, isComplete: false, isRunning: true)
    }
}
