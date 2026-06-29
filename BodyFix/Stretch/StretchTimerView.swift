import AudioToolbox
import SwiftUI
import SwiftData

struct StretchTimerView: View {
    let route: StretchTimerRoute
    @Binding var path: NavigationPath
    let onOnboardingPreviewComplete: (() -> Void)?
    let onOnboardingPreviewCancel: (() -> Void)?
    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarVisibility.self) private var tabBarVisibility
    @Query private var profiles: [UserProfile]

    @State private var currentIndex: Int
    @State private var timeRemaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var holdSegmentStartedAt: Date?
    @State private var holdElapsedBeforeSegment: TimeInterval = 0
    @State private var holdFinished = false
    @State private var holdStarted = false
    @State private var currentRep = 0
    @State private var repPaused = false
    @State private var showEndAlert = false
    @State private var showNextOverlay = false
    @State private var completePulse = false
    @State private var detailStretch: Stretch?
    @State private var savedCompletedStretchIndices: Set<Int> = []
    @State private var countdownValue: Int?
    @State private var countdownTask: Task<Void, Never>?
    @State private var onboardingCompletionTask: Task<Void, Never>?
    @State private var hasRunStartCountdown = false
    @State private var showOnboardingSuccess = false
    @State private var viewedStretchIndices: Set<Int> = []
    @State private var startedStretchIndices: Set<Int> = []
    @State private var completedStretchIndices: Set<Int> = []
    @State private var stretchStartedAt: [Int: Date] = [:]
    @State private var didTrackRoutineStart = false
    @State private var didTrackRoutineCompletion = false
    @State private var didTrackRoutineAbandonment = false
    @State private var routineStartedAt = Date()
    @State private var analyticsSessionId = UUID().uuidString

    private var stretches: [Stretch] {
        route.stretchIds.compactMap { StretchDatabase.stretch(id: $0) }
    }

    private var stretch: Stretch? {
        guard stretches.indices.contains(currentIndex) else { return nil }
        return stretches[currentIndex]
    }

    private var isStartCountdownActive: Bool {
        countdownValue != nil
    }

    private var isOnboardingPreview: Bool {
        route.context == .onboardingPreview
    }

    private func effectiveDuration(for stretch: Stretch) -> Int {
        StretchTimingStore.effectiveDuration(for: stretch, overrides: route.durationOverrides)
    }

    private func effectiveRepCount(for stretch: Stretch) -> Int {
        StretchTimingStore.effectiveRepCount(for: stretch, overrides: route.repOverrides)
    }

    private func timerDetailText(for stretch: Stretch) -> String {
        StretchTimingStore.detailText(
            for: stretch,
            durationOverrides: route.durationOverrides,
            repOverrides: route.repOverrides
        )
    }

    init(
        route: StretchTimerRoute,
        path: Binding<NavigationPath>,
        onOnboardingPreviewComplete: (() -> Void)? = nil,
        onOnboardingPreviewCancel: (() -> Void)? = nil
    ) {
        self.route = route
        _path = path
        self.onOnboardingPreviewComplete = onOnboardingPreviewComplete
        self.onOnboardingPreviewCancel = onOnboardingPreviewCancel
        let list = route.stretchIds.compactMap { StretchDatabase.stretch(id: $0) }
        let idx = min(max(0, route.startIndex), max(0, list.count - 1))
        _currentIndex = State(initialValue: idx)
        if let first = list[safe: idx] {
            _timeRemaining = State(initialValue: route.durationOverrides[first.id] ?? first.duration)
        } else {
            _timeRemaining = State(initialValue: 0)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bfPageBackground, Color.white, Color(hex: "#F6F8FC")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if let stretch {
                mainContent(stretch: stretch)
            } else {
                Text("No stretches")
                    .foregroundStyle(Color.bfTextTertiary)
            }

            if showNextOverlay, stretches.indices.contains(currentIndex + 1) {
                nextInterstitial(name: stretches[currentIndex + 1].name)
            }

            if let countdownValue {
                startCountdownOverlay(value: countdownValue)
            }

            if showOnboardingSuccess {
                onboardingSuccessOverlay
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            tabBarVisibility.suppressTabBar()
            trackRoutineStartedIfNeeded()
            trackStretchViewedIfNeeded()
            startCountdownIfNeeded()
        }
        .onDisappear { tabBarVisibility.restoreTabBar() }
        .alert(isOnboardingPreview ? "Exit this stretch?" : "End routine?", isPresented: $showEndAlert) {
            Button("Continue", role: .cancel) {}
            Button(isOnboardingPreview ? "Exit" : "End") {
                HapticManager.shared.warning()
                exitTimer()
            }
        } message: {
            Text(isOnboardingPreview ? "You can try it again from your plan." : "Your progress will be saved.")
        }
        .onDisappear {
            countdownTask?.cancel()
            countdownTask = nil
            onboardingCompletionTask?.cancel()
            onboardingCompletionTask = nil
            countdownValue = nil
            timer?.invalidate()
        }
        .onChange(of: currentIndex) { _, _ in
            resetForCurrentStretch()
            trackStretchViewedIfNeeded()
        }
        .fullScreenCover(item: $detailStretch) { stretch in
            StretchDetailView(stretch: stretch, detailText: timerDetailText(for: stretch))
        }
    }

    @ViewBuilder
    private func mainContent(stretch: Stretch) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                topBar

                VStack(spacing: 12) {
                    Text(stretch.name)
                        .font(Typography.navTitle)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.bfTextPrimary)
                        .padding(.horizontal, 8)

                    Button {
                        HapticManager.shared.lightImpact()
                        openDetails(for: stretch, trigger: "info_button")
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.bfTextSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                            .overlay(Circle().stroke(Color.bfBorder.opacity(0.6), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }

                if stretch.isRepBased {
                    repTimerContent(stretch: stretch)
                } else {
                    holdTimerContent(stretch: stretch)
                }

                controlButtons(stretch: stretch)

                if stretch.isRepBased, currentRep > 0, !holdFinished {
                    Button {
                        HapticManager.shared.lightImpact()
                        repPaused.toggle()
                    } label: {
                        Text(repPaused ? "Resume reps" : "Pause reps")
                            .font(Typography.homeMeta)
                            .foregroundStyle(Color.bfTextMuted)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.84)))
                            .overlay(Capsule().stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(isStartCountdownActive)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 48)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.mediumImpact()
                showEndAlert = true
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.bfTextPrimary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Color.bfBorder.opacity(0.7), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.06), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isOnboardingPreview ? "Exit stretch preview" : "End routine")

            Spacer()

            HStack(spacing: 10) {
                navigationButton(systemName: "chevron.left", isEnabled: currentIndex > 0) {
                    requestNavigation(to: currentIndex - 1)
                }

                Text("\(currentIndex + 1) of \(stretches.count)")
                    .font(Typography.homeMeta)
                    .foregroundStyle(Color.bfBlue)
                    .frame(minWidth: 70)

                navigationButton(systemName: "chevron.right", isEnabled: currentIndex < stretches.count - 1) {
                    requestNavigation(to: currentIndex + 1)
                }
            }
        }
    }

    @ViewBuilder
    private func holdTimerContent(stretch: Stretch) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isRunning)) { context in
            let elapsed = holdElapsedSeconds(for: stretch, at: context.date)
            let remaining = holdRemainingSeconds(for: stretch, elapsed: elapsed)

            VStack(spacing: 18) {
                progressHeroCircle(
                    stretch: stretch,
                    progress: holdProgress(for: stretch, elapsed: elapsed),
                    ringColor: holdFinished ? Color.bfMint : (isRunning ? Color.bfBlue : Color.bfBlue.opacity(0.6))
                )

                VStack(spacing: 4) {
                    Text(formattedTime(remaining))
                        .font(Typography.timerMonoLarge)
                        .foregroundStyle(Color.bfTextPrimary)
                        .contentTransition(.numericText())
                }
            }
            .onChange(of: elapsed) { _, newElapsed in
                completeHoldIfNeeded(stretch: stretch, elapsed: newElapsed)
            }
        }
    }

    @ViewBuilder
    private func repTimerContent(stretch: Stretch) -> some View {
        let target = effectiveRepCount(for: stretch)
        VStack(spacing: 16) {
            progressHeroCircle(
                stretch: stretch,
                progress: CGFloat(min(currentRep, target)) / CGFloat(max(1, target)),
                ringColor: holdFinished ? Color.bfMint : Color.bfBlue
            )

            VStack(spacing: 4) {
                Text("\(min(currentRep, target)) / \(target)")
                    .font(Typography.timerMonoLarge)
                    .foregroundStyle(Color.bfTextPrimary)
                Text("reps")
                    .font(Typography.timerLabelSmall)
                    .foregroundStyle(Color.bfTextMuted)
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
        transportControls(
            centerSystemName: holdFinished ? "checkmark" : (isRunning ? "pause.fill" : "play.fill"),
            centerStyle: holdFinished ? .complete : (isRunning ? .secondary : .primary),
            centerAction: {
                if holdFinished {
                    HapticManager.shared.mediumImpact()
                    advanceAfterComplete()
                } else if isRunning {
                    HapticManager.shared.mediumImpact()
                    pauseHold()
                } else if holdStarted, holdRemainingSeconds(for: stretch) > 0 {
                    HapticManager.shared.mediumImpact()
                    resumeHold(stretch: stretch)
                } else {
                    startInitialHold(stretch: stretch)
                }
            }
        )
        .scaleEffect(holdFinished && completePulse ? 1.03 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: completePulse)
        .onAppear { if holdFinished { completePulse = true } }
    }

    @ViewBuilder
    private func repControls(stretch: Stretch) -> some View {
        let target = effectiveRepCount(for: stretch)
        transportControls(
            centerSystemName: holdFinished ? "checkmark" : (currentRep == 0 || repPaused ? "play.fill" : "plus"),
            centerStyle: holdFinished ? .complete : (currentRep == 0 ? .primary : .secondary),
            centerAction: {
                if holdFinished {
                    HapticManager.shared.mediumImpact()
                    advanceAfterComplete()
                } else if currentRep == 0 {
                    startInitialRep(stretch: stretch, target: target)
                } else if repPaused {
                    HapticManager.shared.mediumImpact()
                    repPaused = false
                } else if currentRep < target {
                    HapticManager.shared.selection()
                    currentRep += 1
                    if currentRep >= target {
                        holdFinished = true
                        saveCompletedStretchIfNeeded(stretch)
                        HapticManager.shared.success()
                    }
                }
            }
        )
        .scaleEffect(holdFinished && completePulse ? 1.03 : 1)
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: completePulse)
        .onAppear { if holdFinished { completePulse = true } }
    }

    private func startInitialHold(stretch: Stretch) {
        HapticManager.shared.heavyImpact()
        trackStretchStartedIfNeeded(stretch)
        holdStarted = true
        startHoldTimer(stretch: stretch)
    }

    private func startInitialRep(stretch: Stretch, target: Int? = nil) {
        let target = target ?? effectiveRepCount(for: stretch)
        HapticManager.shared.heavyImpact()
        trackStretchStartedIfNeeded(stretch)
        repPaused = false
        currentRep = 1
        if target <= 1 {
            holdFinished = true
            saveCompletedStretchIfNeeded(stretch)
            HapticManager.shared.success()
        }
    }

    private func startCurrentStretchAfterCountdown() {
        guard let stretch else { return }
        if stretch.isRepBased {
            startInitialRep(stretch: stretch)
        } else {
            startInitialHold(stretch: stretch)
        }
    }

    private func startHoldTimer(stretch: Stretch) {
        timer?.invalidate()
        holdSegmentStartedAt = Date()
        isRunning = true
    }

    private func pauseHold() {
        timer?.invalidate()
        if let start = holdSegmentStartedAt {
            holdElapsedBeforeSegment += Date().timeIntervalSince(start)
        }
        holdSegmentStartedAt = nil
        isRunning = false
    }

    private func resumeHold(stretch: Stretch) {
        guard holdRemainingSeconds(for: stretch) > 0 else { return }
        timer?.invalidate()
        holdSegmentStartedAt = Date()
        isRunning = true
    }

    private func resetForCurrentStretch() {
        timer?.invalidate()
        isRunning = false
        holdSegmentStartedAt = nil
        holdElapsedBeforeSegment = 0
        holdFinished = false
        holdStarted = false
        currentRep = 0
        repPaused = false
        completePulse = false
        if let s = stretches[safe: currentIndex] {
            timeRemaining = effectiveDuration(for: s)
        }
    }

    private func startCountdownIfNeeded() {
        guard route.showsStartCountdown,
              route.startIndex == 0,
              currentIndex == 0,
              !hasRunStartCountdown,
              countdownTask == nil,
              stretch != nil else {
            return
        }

        hasRunStartCountdown = true
        countdownTask = Task {
            for value in [3, 2, 1] {
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                        countdownValue = value
                    }
                    CountdownSoundPlayer.shared.playTick()
                    HapticManager.shared.mediumImpact()
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }

            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    countdownValue = nil
                }
                CountdownSoundPlayer.shared.playStart()
                startCurrentStretchAfterCountdown()
                countdownTask = nil
            }
        }
    }

    private func requestNavigation(to index: Int) {
        guard stretches.indices.contains(index), index != currentIndex else { return }
        HapticManager.shared.lightImpact()
        currentIndex = index
    }

    private func exitTimer() {
        timer?.invalidate()
        if isOnboardingPreview {
            onOnboardingPreviewCancel?()
        } else {
            trackRoutineAbandonedIfNeeded()
            path = NavigationPath()
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
        if isOnboardingPreview {
            guard !showOnboardingSuccess else { return }
            timer?.invalidate()
            showOnboardingSuccess = true
            HapticManager.shared.success()
            onboardingCompletionTask = Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    onOnboardingPreviewComplete?()
                }
            }
            return
        }

        trackRoutineCompletedIfNeeded()

        let names = stretches.map(\.name)
        let muscles = orderedMuscleGroupRaws(for: stretches)
        let total = stretches.reduce(0) { partial, stretch in
            partial + effectiveDuration(for: stretch)
        }
        path.append(
            SessionCompleteRoute(
                stretchNames: names,
                muscleGroupRaws: muscles,
                totalSeconds: total,
                routineId: route.routineId,
                routineName: route.routineName,
                seriesId: route.seriesId,
                seriesLevel: route.seriesLevel,
                source: route.source
            )
        )
    }

    private var onboardingSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 86, height: 86)
                    .background(Circle().fill(Color.bfMint))

                Text("Nice work!")
                    .font(Typography.screenTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                Text("Your first stretch is complete.")
                    .font(Typography.subtitle)
                    .foregroundStyle(Color.bfTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 32)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.bfCard))
            .padding(.horizontal, 32)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Nice work. Your first stretch is complete.")
    }

    @ViewBuilder
    private func startCountdownOverlay(value: Int) -> some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            Text("\(value)")
                .font(.system(size: 164, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.24), radius: 18, y: 8)
                .contentTransition(.numericText())
                .id(value)
                .transition(.scale(scale: 0.72).combined(with: .opacity))
        }
        .allowsHitTesting(false)
        .accessibilityLabel("Routine starts in \(value)")
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

    @ViewBuilder
    private func stretchImage(stretch: Stretch, size: CGFloat, cornerRadius: CGFloat) -> some View {
        let image = BodyFixImageResolver.image(for: stretch)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.95), Color.bfSurfaceElevated, Color(hex: "#F6F8FC")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipped()
            } else {
                VStack(spacing: 10) {
                    BodyFixThumbnailView(stretch: stretch, size: 156)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.92), lineWidth: 5)
        )
    }

    private func navigationButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.bfTextSecondary : Color.bfTextDisabled.opacity(0.7))
                .frame(width: 30, height: 30)
                .background(
                    Circle()
                        .fill(Color.bfSurfaceElevated)
                )
                .overlay(
                    Circle()
                        .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
    }

    @ViewBuilder
    private func transportControls(
        centerSystemName: String,
        centerStyle: TimerPrimaryButtonStyle,
        centerAction: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 26) {
            transportSideButton(systemName: "backward.fill", isEnabled: currentIndex > 0) {
                requestNavigation(to: currentIndex - 1)
            }

            transportPrimaryButton(systemName: centerSystemName, style: centerStyle, action: centerAction)

            transportSideButton(systemName: "forward.fill", isEnabled: currentIndex < stretches.count - 1) {
                requestNavigation(to: currentIndex + 1)
            }
        }
        .disabled(isStartCountdownActive)
        .opacity(isStartCountdownActive ? 0.58 : 1)
    }

    private func transportSideButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isEnabled ? Color.bfTextSecondary : Color.bfTextDisabled.opacity(0.8))
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.white.opacity(0.9)))
                .overlay(Circle().stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isStartCountdownActive)
        .opacity(isEnabled && !isStartCountdownActive ? 1 : 0.55)
    }

    private func transportPrimaryButton(systemName: String, style: TimerPrimaryButtonStyle, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(style.foreground)
                .frame(width: 84, height: 84)
                .background(
                    Circle()
                        .fill(style.fill)
                )
                .overlay(
                    Circle()
                        .stroke(style.stroke, lineWidth: style.lineWidth)
                )
                .shadow(color: style.shadowColor, radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func holdElapsedSeconds(for stretch: Stretch, at date: Date = Date()) -> Double {
        var elapsed = holdElapsedBeforeSegment
        if isRunning, let start = holdSegmentStartedAt {
            elapsed += date.timeIntervalSince(start)
        }
        return min(Double(effectiveDuration(for: stretch)), elapsed)
    }

    private func holdRemainingSeconds(for stretch: Stretch, elapsed: Double? = nil, at date: Date = Date()) -> Int {
        let total = effectiveDuration(for: stretch)
        let consumed = elapsed ?? holdElapsedSeconds(for: stretch, at: date)
        let remaining = Double(total) - consumed
        return max(0, Int(ceil(remaining - 0.000_001)))
    }

    private func holdProgress(for stretch: Stretch, elapsed: Double? = nil) -> CGFloat {
        let total = max(1, effectiveDuration(for: stretch))
        let consumed = elapsed ?? holdElapsedSeconds(for: stretch)
        return CGFloat(consumed / Double(total))
    }

    private func completeHoldIfNeeded(stretch: Stretch, elapsed: Double) {
        guard isRunning, !holdFinished else { return }
        let total = Double(effectiveDuration(for: stretch))
        guard elapsed >= total else { return }
        holdElapsedBeforeSegment = total
        holdSegmentStartedAt = nil
        isRunning = false
        holdFinished = true
        timeRemaining = 0
        saveCompletedStretchIfNeeded(stretch)
        HapticManager.shared.success()
    }

    private func saveCompletedStretchIfNeeded(_ stretch: Stretch) {
        trackStretchCompletedIfNeeded(stretch)
        guard !isOnboardingPreview else { return }
        guard !savedCompletedStretchIndices.contains(currentIndex) else { return }
        savedCompletedStretchIndices.insert(currentIndex)

        modelContext.insert(
            StretchSession(
                muscleGroups: orderedMuscleGroupRaws(for: [stretch]),
                stretchNames: [stretch.name],
                totalDuration: effectiveDuration(for: stretch),
                stretchCount: 1
            )
        )

        if let profile = profiles.first {
            StreakUpdater.applySessionCompletion(to: profile, at: Date())
        }

        try? modelContext.save()
    }

    private func openDetails(for stretch: Stretch, trigger: String) {
        var properties = stretchAnalyticsProperties(for: stretch)
        properties["trigger"] = trigger
        properties["has_started"] = startedStretchIndices.contains(currentIndex)
        properties["is_completed"] = completedStretchIndices.contains(currentIndex)
        AnalyticsTracker.capture(AnalyticsEvent.stretchInfoOpened, properties: properties)
        detailStretch = stretch
    }

    private func trackRoutineStartedIfNeeded() {
        guard !isOnboardingPreview, !didTrackRoutineStart else { return }
        didTrackRoutineStart = true
        routineStartedAt = Date()
        AnalyticsTracker.capture(
            AnalyticsEvent.routineStarted,
            properties: routineAnalyticsProperties()
        )
    }

    private func trackRoutineCompletedIfNeeded() {
        guard !isOnboardingPreview, !didTrackRoutineCompletion else { return }
        didTrackRoutineCompletion = true
        var properties = routineAnalyticsProperties()
        properties["elapsed_seconds"] = max(0, Date().timeIntervalSince(routineStartedAt))
        properties["completed_stretch_count"] = completedStretchIndices.count
        AnalyticsTracker.capture(AnalyticsEvent.routineCompleted, properties: properties)
    }

    private func trackRoutineAbandonedIfNeeded() {
        guard !isOnboardingPreview,
              didTrackRoutineStart,
              !didTrackRoutineCompletion,
              !didTrackRoutineAbandonment
        else { return }

        didTrackRoutineAbandonment = true
        var properties = routineAnalyticsProperties()
        properties["elapsed_seconds"] = max(0, Date().timeIntervalSince(routineStartedAt))
        properties["completed_stretch_count"] = completedStretchIndices.count
        properties["exit_stretch_index"] = currentIndex
        AnalyticsTracker.capture(AnalyticsEvent.routineAbandoned, properties: properties)
    }

    private func trackStretchViewedIfNeeded() {
        guard let stretch, !viewedStretchIndices.contains(currentIndex) else { return }
        viewedStretchIndices.insert(currentIndex)
        AnalyticsTracker.capture(
            AnalyticsEvent.stretchViewed,
            properties: stretchAnalyticsProperties(for: stretch)
        )
    }

    private func trackStretchStartedIfNeeded(_ stretch: Stretch) {
        guard !startedStretchIndices.contains(currentIndex) else { return }
        startedStretchIndices.insert(currentIndex)
        stretchStartedAt[currentIndex] = Date()
        AnalyticsTracker.capture(
            AnalyticsEvent.stretchStarted,
            properties: stretchAnalyticsProperties(for: stretch)
        )
    }

    private func trackStretchCompletedIfNeeded(_ stretch: Stretch) {
        guard !completedStretchIndices.contains(currentIndex) else { return }
        completedStretchIndices.insert(currentIndex)
        var properties = stretchAnalyticsProperties(for: stretch)
        if let startedAt = stretchStartedAt[currentIndex] {
            properties["elapsed_seconds"] = max(0, Date().timeIntervalSince(startedAt))
        }
        AnalyticsTracker.capture(AnalyticsEvent.stretchCompleted, properties: properties)
    }

    private func routineAnalyticsProperties() -> [String: Any] {
        var properties: [String: Any] = [
            "routine_session_id": analyticsSessionId,
            "routine_source": route.source.rawValue,
            "stretch_count": stretches.count,
            "start_index": route.startIndex,
            "planned_duration_seconds": stretches.reduce(0) { partial, stretch in
                partial + effectiveDuration(for: stretch)
            },
        ]
        if let routineId = route.routineId {
            properties["routine_id"] = routineId
        }
        if let routineName = route.routineName {
            properties["routine_name"] = routineName
        }
        if let seriesId = route.seriesId {
            properties["series_id"] = seriesId
        }
        if let seriesLevel = route.seriesLevel {
            properties["series_level"] = seriesLevel
        }
        return properties
    }

    private func stretchAnalyticsProperties(for stretch: Stretch) -> [String: Any] {
        var properties = routineAnalyticsProperties()
        properties["stretch_id"] = stretch.id
        properties["stretch_name"] = stretch.name
        properties["stretch_index"] = currentIndex
        properties["stretch_number"] = currentIndex + 1
        properties["duration_seconds"] = effectiveDuration(for: stretch)
        properties["is_rep_based"] = stretch.isRepBased
        properties["context"] = isOnboardingPreview ? "onboarding_preview" : "standard"
        return properties
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):" + String(format: "%02d", seconds)
    }

    @ViewBuilder
    private func progressHeroCircle(stretch: Stretch, progress: CGFloat, ringColor: Color) -> some View {
        let heroSize: CGFloat = 292
        let cornerRadius: CGFloat = 48
        let imageInset: CGFloat = 22
        let imageSize = heroSize - (imageInset * 2)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .frame(width: heroSize, height: heroSize)
                .shadow(color: Color.black.opacity(0.04), radius: 20, y: 10)

            Button {
                HapticManager.shared.lightImpact()
                openDetails(for: stretch, trigger: "timer_image")
            } label: {
                stretchImage(stretch: stretch, size: imageSize, cornerRadius: cornerRadius - 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open details for \(stretch.name)")

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.bfSurfaceMuted.opacity(0.95), lineWidth: 12)
                .frame(width: heroSize, height: heroSize)

            RoundedSquareProgressShape(
                progress: max(0, min(progress, 1)),
                cornerRadius: cornerRadius
            )
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: heroSize, height: heroSize)
                .animation(.easeInOut(duration: 0.35), value: holdFinished)
        }
        .frame(maxWidth: .infinity)
    }

    private func orderedMuscleGroupRaws(for stretches: [Stretch]) -> [String] {
        let rawGroups = Set(stretches.flatMap(\.muscleGroups))
        return MuscleGroup.allCases.map(\.rawValue).filter(rawGroups.contains)
    }
}

struct StretchComparisonView: View {
    let stretch: Stretch

    private var beforeImage: UIImage? {
        BodyFixImageResolver.beforeImage(for: stretch)
    }

    private var afterImage: UIImage? {
        BodyFixImageResolver.afterImage(for: stretch)
    }

    var body: some View {
        if beforeImage != nil || afterImage != nil {
            if let beforeImage, let afterImage {
                HStack(spacing: 12) {
                    comparisonPanel(image: beforeImage, label: "Before")
                    comparisonPanel(image: afterImage, label: "After")
                }
                .padding(.top, 2)
            } else if let image = beforeImage ?? afterImage {
                comparisonPanel(image: image, label: beforeImage == nil ? "After" : "Before")
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
    }

    private func comparisonPanel(image: UIImage, label: String) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .overlay(alignment: .topLeading) {
                Text(label)
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfTextPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.68), lineWidth: 1)
                    )
                    .padding(10)
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.bfSurfaceElevated)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.bfBorder.opacity(0.62), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 14, y: 7)
            .accessibilityLabel("\(label) position for \(stretch.name)")
    }
}

private struct RoundedSquareProgressShape: Shape {
    let progress: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let basePath = Path(
            roundedRect: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            style: .continuous
        )

        return basePath.trimmedPath(from: 0, to: progress)
    }
}

private final class CountdownSoundPlayer {
    static let shared = CountdownSoundPlayer()

    private let tickSound: SystemSoundID = 1104
    private let startSound: SystemSoundID = 1057

    private init() {}

    func playTick() {
        AudioServicesPlaySystemSound(tickSound)
    }

    func playStart() {
        AudioServicesPlaySystemSound(startSound)
    }
}

private enum TimerPrimaryButtonStyle {
    case primary
    case secondary
    case complete

    var fill: AnyShapeStyle {
        switch self {
        case .primary:
            return AnyShapeStyle(LinearGradient(colors: [Color.bfBlue, Color(hex: "#5E83CD")], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .secondary:
            return AnyShapeStyle(Color.white.opacity(0.94))
        case .complete:
            return AnyShapeStyle(Color.bfMint)
        }
    }

    var stroke: Color {
        switch self {
        case .secondary: return Color.bfBorder.opacity(0.6)
        default: return .clear
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .secondary: return 1
        default: return 0
        }
    }

    var foreground: Color {
        switch self {
        case .primary, .complete: return .white
        case .secondary: return Color.bfTextPrimary
        }
    }

    var shadowColor: Color {
        switch self {
        case .primary:
            return Color.bfBlue.opacity(0.18)
        case .complete:
            return Color.bfMint.opacity(0.22)
        case .secondary:
            return Color.black.opacity(0.05)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
