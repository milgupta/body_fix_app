import AVKit
import Combine
import SwiftUI

struct StretchDetailView: View {
    let stretch: Stretch
    let detailText: String

    @Environment(\.dismiss) private var dismiss
    @State private var videoPresentationSize: CGSize = .zero

    private var usesLandscapeVideoLayout: Bool {
        videoPresentationSize.width > videoPresentationSize.height && videoPresentationSize.height > 0
    }

    var body: some View {
        GeometryReader { proxy in
            let heroHeight = heroHeight(for: proxy)

            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        StretchDetailHeroMedia(
                            stretch: stretch,
                            topContentInset: proxy.safeAreaInsets.top + 12,
                            videoGravity: usesLandscapeVideoLayout ? .resizeAspectFill : .resizeAspect,
                            onPresentationSizeChange: { size in
                                guard videoPresentationSize != size else { return }
                                videoPresentationSize = size
                            }
                        )
                            .frame(height: heroHeight)

                        detailPanel
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .ignoresSafeArea(edges: .top)

                closeButton
                    .padding(.top, proxy.safeAreaInsets.top + 14)
                    .padding(.trailing, 22)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
        }
    }

    private func heroHeight(for proxy: GeometryProxy) -> CGFloat {
        return max(460, proxy.size.height * 0.62)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.bfHeroSurface.opacity(0.72)))
                .overlay(Circle().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 28) {
            Capsule()
                .fill(Color.bfBorder.opacity(0.72))
                .frame(width: 60, height: 7)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)

            VStack(alignment: .leading, spacing: 26) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(stretch.name)
                        .font(Typography.navTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                instructionsSection

                targetsSection
            }
            .padding(.horizontal, 34)
            .padding(.bottom, 44)
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32)
                .fill(Color.white)
        )
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("Instructions")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(instructionSteps.enumerated()), id: \.offset) { index, step in
                    InstructionStepRow(text: step, showsLine: index < instructionSteps.count - 1)
                }
            }
        }
    }

    private var targetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionLabel("Targets")

            FlowLayout(spacing: 10, rowSpacing: 10) {
                ForEach(stretch.muscles) { muscle in
                    Text(muscle.displayName)
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfMint)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Color.bfBorder.opacity(0.45)))
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .tracking(0.8)
            .foregroundStyle(Color.bfTextMuted)
    }

    private var instructionSteps: [String] {
        let cleaned = stretch.description
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let sentences = cleaned.matches(for: #"[^.!?]+[.!?]?"#)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return sentences.isEmpty ? [cleaned] : sentences
    }
}

private struct StretchDetailHeroMedia: View {
    let stretch: Stretch
    let topContentInset: CGFloat
    let videoGravity: AVLayerVideoGravity
    let onPresentationSizeChange: (CGSize) -> Void

    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var mediaState: HeroMediaState = .loadingVideo
    @State private var loopObserver: NSObjectProtocol?

    private var videoURL: URL? {
        StretchVideoDatabase.hlsURL(for: stretch.id)
    }

    private var mediaTopPadding: CGFloat {
        max(32, topContentInset)
    }

    private var playerStatusPublisher: AnyPublisher<AVPlayerItem.Status, Never> {
        playerItem?.publisher(for: \.status).eraseToAnyPublisher() ?? Empty().eraseToAnyPublisher()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.bfHeroSurface, Color.bfHeroSurfaceSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            switch mediaState {
            case .loadingVideo:
                loadingVideoView
            case .playingVideo:
                if let player {
                    StretchVideoPlayer(player: player, videoGravity: videoGravity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    loadingVideoView
                }
            case .fallbackImage:
                fallbackImage
            }
        }
        .onReceive(playerStatusPublisher) { status in
            handlePlayerStatus(status)
        }
        .clipped()
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [.clear, Color.bfHeroSurface.opacity(0.42)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
        }
        .overlay {
            mediaFadeOverlay
                .allowsHitTesting(false)
        }
        .task(id: stretch.id) {
            prepareVideo()
        }
        .onDisappear {
            resetPlayer()
        }
    }

    private var loadingVideoView: some View {
        ZStack {
            Color.black

            StretchVideoLoadingDots()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func prepareVideo() {
        resetPlayer()
        onPresentationSizeChange(.zero)

        guard let videoURL else {
            mediaState = .fallbackImage
            return
        }

        mediaState = .loadingVideo

        let item = AVPlayerItem(url: videoURL)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.isMuted = true
        playerItem = item
        player = newPlayer
        newPlayer.play()
    }

    private func handlePlayerStatus(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            onPresentationSizeChange(playerItem?.presentationSize ?? .zero)
            mediaState = .playingVideo
            installLoopObserver()
            player?.play()
        case .failed:
            onPresentationSizeChange(.zero)
            mediaState = .fallbackImage
            resetPlayer(keepsFallbackState: true)
        default:
            break
        }
    }

    private func installLoopObserver() {
        removeLoopObserver()

        guard let playerItem else { return }

        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    private func removeLoopObserver() {
        if let loopObserver {
            NotificationCenter.default.removeObserver(loopObserver)
            self.loopObserver = nil
        }
    }

    private func resetPlayer(keepsFallbackState: Bool = false) {
        removeLoopObserver()
        player?.pause()
        player = nil
        playerItem = nil

        if !keepsFallbackState {
            mediaState = .loadingVideo
        }
    }

    private var mediaFadeOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.bfHeroSurface.opacity(0.18),
                    .clear,
                    .clear,
                    Color.bfHeroSurface.opacity(0.18),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            LinearGradient(
                colors: [Color.bfHeroSurface.opacity(0.24), .clear, Color.bfHeroSurface.opacity(0.36)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var fallbackImage: some View {
        let beforeImage = BodyFixImageResolver.beforeImage(for: stretch)
        let afterImage = BodyFixImageResolver.afterImage(for: stretch)
        let primaryImage = afterImage ?? beforeImage ?? BodyFixImageResolver.image(for: stretch)

        if beforeImage != nil, afterImage != nil {
            HStack(spacing: 0) {
                fallbackPanel(image: beforeImage)
                fallbackPanel(image: afterImage)
            }
        } else if let primaryImage {
            Image(uiImage: primaryImage)
                .resizable()
                .scaledToFit()
                .padding(.top, mediaTopPadding)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Image(systemName: "figure.flexibility")
                .font(.system(size: 116, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.88))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fallbackPanel(image: UIImage?) -> some View {
        ZStack {
            Color.clear

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(.top, mediaTopPadding)
                    .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum HeroMediaState {
    case loadingVideo
    case playingVideo
    case fallbackImage
}

private struct StretchVideoLoadingDots: View {
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 10

    var body: some View {
        TimelineView(.animation) { timeline in
            let phase = Int((timeline.date.timeIntervalSinceReferenceDate * 3).rounded(.down)) % 3

            HStack(spacing: dotSpacing) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == phase ? Color.bfMint : Color.white.opacity(0.72))
                        .frame(width: dotSize, height: dotSize)
                        .opacity(index == phase ? 0.96 : 0.54)
                        .scaleEffect(index == phase ? 1.22 : 1.0)
                        .animation(.easeInOut(duration: 0.22), value: phase)
                }
            }
            .accessibilityLabel("Loading video")
        }
    }
}

private struct StretchVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let playerView = StretchPlayerView()
        player.isMuted = true
        playerView.playerLayer.player = player
        playerView.playerLayer.videoGravity = videoGravity
        playerView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.backgroundColor = .white
        controller.view.addSubview(playerView)
        NSLayoutConstraint.activate([
            playerView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            playerView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            playerView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
        ])
        return controller
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        controller.view.backgroundColor = .white
        player.isMuted = true

        if let playerView = controller.view.subviews.first as? StretchPlayerView {
            if playerView.playerLayer.player !== player {
                playerView.playerLayer.player = player
            }
            playerView.playerLayer.videoGravity = videoGravity
        }
    }
}

private final class StretchPlayerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        playerLayer.backgroundColor = UIColor.white.cgColor
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        playerLayer.backgroundColor = UIColor.white.cgColor
        playerLayer.videoGravity = .resizeAspect
    }
}

private struct InstructionStepRow: View {
    let text: String
    let showsLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            ZStack(alignment: .top) {
                if showsLine {
                    Rectangle()
                        .fill(Color.bfBorder)
                        .frame(width: 3)
                        .padding(.top, 23)
                        .padding(.bottom, -1)
                }

                Circle()
                    .fill(Color.bfBlue)
                    .frame(width: 13, height: 13)
                    .padding(5)
                    .background(Circle().fill(Color.bfBlue.opacity(0.14)))
            }
            .frame(width: 24)
            .frame(maxHeight: .infinity)

            Text(text)
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, -1)
                .padding(.bottom, showsLine ? 22 : 0)
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, in: proposal.width ?? .infinity)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.last.map { $0.y + $0.height } ?? 0
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, in: bounds.width)
        for row in rows {
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: bounds.minX + item.x, y: bounds.minY + row.y),
                    proposal: ProposedViewSize(item.size)
                )
            }
        }
    }

    private func rows(for subviews: Subviews, in maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentItems: [Item] = []
        var currentX: CGFloat = 0
        var currentHeight: CGFloat = 0
        var currentY: CGFloat = 0
        let availableWidth = maxWidth.isFinite ? maxWidth : CGFloat.greatestFiniteMagnitude

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let nextX = currentItems.isEmpty ? 0 : currentX + spacing
            if !currentItems.isEmpty, nextX + size.width > availableWidth {
                rows.append(Row(y: currentY, height: currentHeight, width: currentX, items: currentItems))
                currentY += currentHeight + rowSpacing
                currentItems = []
                currentX = 0
                currentHeight = 0
            }

            let itemX = currentItems.isEmpty ? 0 : currentX + spacing
            currentItems.append(Item(index: index, x: itemX, size: size))
            currentX = itemX + size.width
            currentHeight = max(currentHeight, size.height)
        }

        if !currentItems.isEmpty {
            rows.append(Row(y: currentY, height: currentHeight, width: currentX, items: currentItems))
        }

        return rows
    }

    private struct Row {
        let y: CGFloat
        let height: CGFloat
        let width: CGFloat
        let items: [Item]
    }

    private struct Item {
        let index: Int
        let x: CGFloat
        let size: CGSize
    }
}

private extension String {
    func matches(for pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let matchRange = Range(match.range, in: self) else { return nil }
            return String(self[matchRange])
        }
    }
}
