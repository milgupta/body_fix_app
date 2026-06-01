import SwiftUI
import SwiftData

struct StretchTimerView: View {
    let route: StretchTimerRoute
    @Binding var path: NavigationPath
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
    @State private var showSkipAlert = false
    @State private var showNextOverlay = false
    @State private var completePulse = false
    @State private var pendingNavigationIndex: Int?
    @State private var showInstructions = false
    @State private var savedCompletedStretchIndices: Set<Int> = []

    private var stretches: [Stretch] {
        route.stretchIds.compactMap { StretchDatabase.stretch(id: $0) }
    }

    private var stretch: Stretch? {
        guard stretches.indices.contains(currentIndex) else { return nil }
        return stretches[currentIndex]
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

    init(route: StretchTimerRoute, path: Binding<NavigationPath>) {
        self.route = route
        _path = path
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
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear { tabBarVisibility.suppressTabBar() }
        .onDisappear { tabBarVisibility.restoreTabBar() }
        .alert("End routine?", isPresented: $showEndAlert) {
            Button("Continue", role: .cancel) {}
            Button("End") {
                HapticManager.shared.warning()
                path = NavigationPath()
            }
        } message: {
            Text("Your progress will be saved.")
        }
        .alert("Skip this stretch?", isPresented: $showSkipAlert) {
            Button("Stay", role: .cancel) {
                pendingNavigationIndex = nil
            }
            Button("Skip") {
                HapticManager.shared.warning()
                applyPendingNavigation()
            }
        } message: {
            Text("Your progress on this stretch will reset.")
        }
        .onDisappear {
            timer?.invalidate()
        }
        .onChange(of: currentIndex) { _, _ in
            resetForCurrentStretch()
        }
        .sheet(isPresented: $showInstructions) {
            if let stretch {
                instructionsSheet(for: stretch)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
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
                        showInstructions = true
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
            .accessibilityLabel("End routine")

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
                    HapticManager.shared.heavyImpact()
                    holdStarted = true
                    startHoldTimer(stretch: stretch)
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
                    HapticManager.shared.heavyImpact()
                    repPaused = false
                    currentRep = 1
                    if target <= 1 {
                        holdFinished = true
                        saveCompletedStretchIfNeeded(stretch)
                        HapticManager.shared.success()
                    }
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

    private func requestNavigation(to index: Int) {
        guard stretches.indices.contains(index), index != currentIndex else { return }
        HapticManager.shared.lightImpact()
        if hasInProgressState {
            pendingNavigationIndex = index
            showSkipAlert = true
        } else {
            currentIndex = index
        }
    }

    private func applyPendingNavigation() {
        guard let index = pendingNavigationIndex, stretches.indices.contains(index) else { return }
        pendingNavigationIndex = nil
        currentIndex = index
    }

    private var hasInProgressState: Bool {
            if let stretch {
                if stretch.isRepBased {
                    let target = effectiveRepCount(for: stretch)
                    return currentRep > 0 && currentRep < target && !holdFinished
                }
                return holdStarted && !holdFinished
            }
        return false
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
        let total = stretches.reduce(0) { partial, stretch in
            partial + effectiveDuration(for: stretch)
        }
        path.append(
            SessionCompleteRoute(
                stretchNames: names,
                muscleGroupRaws: muscles,
                totalSeconds: total,
                routineName: route.routineName,
                seriesId: route.seriesId,
                seriesLevel: route.seriesLevel
            )
        )
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
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
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

    @ViewBuilder
    private func instructionsSheet(for stretch: Stretch) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(stretch.name)
                        .font(Typography.navTitle)
                        .foregroundStyle(Color.bfTextPrimary)

                    Text(timerDetailText(for: stretch))
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.bfBlue.opacity(0.08))
                        .clipShape(Capsule())

                    StretchComparisonView(stretch: stretch)

                    Text(stretch.description)
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.bfTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
            .background(Color.bfPageBackground)
        }
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
        guard !savedCompletedStretchIndices.contains(currentIndex) else { return }
        savedCompletedStretchIndices.insert(currentIndex)

        modelContext.insert(
            StretchSession(
                muscleGroups: [stretch.muscleGroup],
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

            stretchImage(stretch: stretch, size: imageSize, cornerRadius: cornerRadius - 12)

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
}

private struct StretchComparisonView: View {
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
