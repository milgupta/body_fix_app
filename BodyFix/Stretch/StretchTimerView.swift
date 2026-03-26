import SwiftUI

struct StretchTimerView: View {
    let route: StretchTimerRoute
    @Binding var path: NavigationPath

    @State private var currentIndex: Int
    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var holdFinished = false
    @State private var holdStarted = false
    @State private var currentRep = 0
    @State private var repPaused = false
    @State private var showEndAlert = false
    @State private var showNextOverlay = false
    @State private var completePulse = false

    private var stretches: [Stretch] {
        route.stretchIds.compactMap { StretchDatabase.stretch(id: $0) }
    }

    private var stretch: Stretch? {
        guard stretches.indices.contains(currentIndex) else { return nil }
        return stretches[currentIndex]
    }

    init(route: StretchTimerRoute, path: Binding<NavigationPath>) {
        self.route = route
        _path = path
        let list = route.stretchIds.compactMap { StretchDatabase.stretch(id: $0) }
        let idx = min(max(0, route.startIndex), max(0, list.count - 1))
        _currentIndex = State(initialValue: idx)
        if let first = list[safe: idx] {
            _timeRemaining = State(initialValue: first.duration)
        } else {
            _timeRemaining = State(initialValue: 0)
        }
    }

    var body: some View {
        ZStack {
            Color.bfBackground.ignoresSafeArea()

            if let stretch {
                mainContent(stretch: stretch)
            } else {
                Text("No stretches")
                    .foregroundStyle(Color.bfTextTertiary)
            }

            if showNextOverlay, stretches.indices.contains(currentIndex + 1) {
                nextInterstitial(name: stretches[currentIndex + 1].name)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .alert("End routine?", isPresented: $showEndAlert) {
            Button("Continue", role: .cancel) {}
            Button("End") {
                path = NavigationPath()
            }
        } message: {
            Text("Your progress will be saved.")
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: currentIndex) { _, _ in
            resetForCurrentStretch()
        }
    }

    @ViewBuilder
    private func mainContent(stretch: Stretch) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    HapticManager.shared.mediumImpact()
                    showEndAlert = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.bfTextSecondary)
                }
                Spacer()
                Text("\(currentIndex + 1) of \(stretches.count)")
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.bfMint)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer().frame(height: 24)

            Text(stretch.name)
                .font(Typography.navTitle)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.bfTextPrimary)
                .padding(.horizontal, 20)

            Text(stretch.repScheme)
                .font(Typography.badgeMono)
                .foregroundStyle(Color.bfMint)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.bfBlue.opacity(0.08))
                .clipShape(Capsule())
                .padding(.top, 10)

            Spacer().frame(height: 28)

            if stretch.isRepBased {
                repTimerContent(stretch: stretch)
            } else {
                holdTimerContent(stretch: stretch)
            }

            Text(stretch.description)
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
                .padding(.top, 24)
                .padding(.horizontal, 20)

            Spacer()

            controlButtons(stretch: stretch)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    private func holdTimerContent(stretch: Stretch) -> some View {
        CircularTimerView(
            totalSeconds: max(1, stretch.duration),
            remainingSeconds: timeRemaining,
            isComplete: holdFinished,
            isRunning: isRunning
        )
    }

    @ViewBuilder
    private func repTimerContent(stretch: Stretch) -> some View {
        let target = stretch.targetReps
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.bfCard, lineWidth: 8)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: CGFloat(min(currentRep, target)) / CGFloat(max(1, target)))
                    .stroke(
                        holdFinished ? Color.bfMint : Color.bfBlue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: currentRep)

                VStack(spacing: 6) {
                    Text("\(min(currentRep, target)) / \(target)")
                        .font(Typography.timerMonoLarge)
                        .foregroundStyle(Color.bfTextPrimary)
                    Text("REPS")
                        .font(Typography.timerLabelSmall)
                        .foregroundStyle(Color.bfTextMuted)
                }
            }
            .frame(width: 200, height: 200)

            if currentRep > 0, currentRep < target, !repPaused {
                Button {
                    HapticManager.shared.mediumImpact()
                    currentRep += 1
                    if currentRep >= target {
                        holdFinished = true
                        HapticManager.shared.success()
                    }
                } label: {
                    Text("Next rep")
                        .font(Typography.primaryCta)
                        .foregroundStyle(Color.bfTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfCard))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfBorder))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func controlButtons(stretch: Stretch) -> some View {
        if stretch.isRepBased {
            repControls(stretch: stretch)
        } else {
            holdControls(stretch: stretch)
        }
    }

    @ViewBuilder
    private func holdControls(stretch: Stretch) -> some View {
        if holdFinished {
            Button {
                HapticManager.shared.mediumImpact()
                advanceAfterComplete()
            } label: {
                Text("Complete ✓")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfMint))
            }
            .buttonStyle(.plain)
            .scaleEffect(completePulse ? 1.03 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: completePulse)
            .onAppear { completePulse = true }
        } else if isRunning {
            Button {
                HapticManager.shared.mediumImpact()
                pauseHold()
            } label: {
                Text("Pause")
                    .font(Typography.primaryCta)
                    .foregroundStyle(Color.bfTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfCard))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfBorder))
            }
            .buttonStyle(.plain)
        } else if holdStarted, timeRemaining > 0 {
            Button {
                HapticManager.shared.mediumImpact()
                resumeHold(stretch: stretch)
            } label: {
                Text("Resume")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.bfGradient))
            }
            .buttonStyle(.plain)
        } else {
            GradientButton(title: "Start Timer", showShadow: true) {
                HapticManager.shared.heavyImpact()
                holdStarted = true
                startHoldTimer(stretch: stretch)
            }
        }
    }

    @ViewBuilder
    private func repControls(stretch: Stretch) -> some View {
        let target = stretch.targetReps
        if holdFinished {
            Button {
                HapticManager.shared.mediumImpact()
                advanceAfterComplete()
            } label: {
                Text("Complete ✓")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfMint))
            }
            .buttonStyle(.plain)
            .scaleEffect(completePulse ? 1.03 : 1)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: completePulse)
            .onAppear { completePulse = true }
        } else if currentRep == 0 {
            GradientButton(title: "Start", showShadow: true) {
                HapticManager.shared.heavyImpact()
                repPaused = false
                currentRep = 1
                if target <= 1 {
                    holdFinished = true
                    HapticManager.shared.success()
                }
            }
        } else if currentRep < target {
            Button {
                HapticManager.shared.mediumImpact()
                repPaused.toggle()
            } label: {
                Text(repPaused ? "Resume" : "Pause")
                    .font(Typography.primaryCta)
                    .foregroundStyle(Color.bfTextTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfCard))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfBorder))
            }
            .buttonStyle(.plain)
        }
    }

    private func startHoldTimer(stretch: Stretch) {
        timer?.invalidate()
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
                if timeRemaining == 0 {
                    timer?.invalidate()
                    isRunning = false
                    holdFinished = true
                    HapticManager.shared.success()
                }
            }
        }
    }

    private func pauseHold() {
        timer?.invalidate()
        isRunning = false
    }

    private func resumeHold(stretch: Stretch) {
        guard timeRemaining > 0 else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
                if timeRemaining == 0 {
                    timer?.invalidate()
                    isRunning = false
                    holdFinished = true
                    HapticManager.shared.success()
                }
            }
        }
    }

    private func resetForCurrentStretch() {
        timer?.invalidate()
        isRunning = false
        holdFinished = false
        holdStarted = false
        currentRep = 0
        repPaused = false
        completePulse = false
        if let s = stretches[safe: currentIndex] {
            timeRemaining = s.duration
        }
    }

    private func advanceAfterComplete() {
        if currentIndex + 1 < stretches.count {
            showNextOverlay = true
            HapticManager.shared.mediumImpact()
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    showNextOverlay = false
                    currentIndex += 1
                }
            }
        } else {
            finishSession()
        }
    }

    private func finishSession() {
        let names = stretches.map(\.name)
        let muscles = Array(Set(stretches.map(\.muscleGroup))).sorted()
        let total = stretches.reduce(0) { $0 + $1.duration }
        path.append(SessionCompleteRoute(stretchNames: names, muscleGroupRaws: muscles, totalSeconds: total))
    }

    @ViewBuilder
    private func nextInterstitial(name: String) -> some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Next:")
                    .font(Typography.screenSubtitle)
                    .foregroundStyle(Color.bfTextTertiary)
                Text(name)
                    .font(Typography.navTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.bfTextPrimary)
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.bfCard))
            .padding(32)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
