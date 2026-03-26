import SwiftUI
import SwiftData
import UIKit

struct SessionCompleteView: View {
    let route: SessionCompleteRoute
    @Binding var path: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var checkScale: CGFloat = 0
    @State private var shareImage: UIImage?
    @State private var didSave = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ZStack {
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.bfMint)
                            .frame(width: 100, height: 100)
                        Image(systemName: "checkmark")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(checkScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                            checkScale = 1
                        }
                    }

                    Text("Great work!")
                        .font(Typography.screenTitle)
                        .foregroundStyle(Color.bfTextPrimary)

                    statsGrid

                    shareCardPreview
                        .padding(.horizontal, 4)

                    if let shareImage {
                        shareButton(image: shareImage)
                    }

                    Button {
                        HapticManager.shared.mediumImpact()
                        path = NavigationPath()
                    } label: {
                        Text("Done")
                            .font(Typography.primaryCta)
                            .foregroundStyle(Color.bfTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.bfCard))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.bfBorder))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 48)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            guard !didSave else { return }
            didSave = true
            saveSession()
            renderShareImage()
        }
    }

    private var statsGrid: some View {
        let streak = profile?.stretchStreak ?? 0
        let minutes = max(1, route.totalSeconds / 60)
        return HStack(alignment: .top, spacing: 12) {
            statCell(value: "\(minutes)", label: "Total time")
            statCell(value: "\(route.stretchNames.count)", label: "Stretches")
            statCell(value: "\(streak)", label: "Day streak")
        }
        .padding(.horizontal, 20)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.bfMint)
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color.bfTextTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var shareCardPreview: some View {
        ShareSessionCardView(
            muscleGroups: route.muscleGroupRaws,
            totalSeconds: route.totalSeconds,
            streak: profile?.stretchStreak ?? 0
        )
    }

    @ViewBuilder
    private func shareButton(image: UIImage) -> some View {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("bodyfix-session.png")
        if let data = image.pngData() {
            try? data.write(to: url)
            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.bfGradient))
            }
            .padding(.horizontal, 20)
        }
    }

    private func saveSession() {
        let session = StretchSession(
            muscleGroups: route.muscleGroupRaws,
            stretchNames: route.stretchNames,
            totalDuration: route.totalSeconds,
            stretchCount: route.stretchNames.count
        )
        modelContext.insert(session)

        guard let p = profile else { return }
        StreakUpdater.applySessionCompletion(to: p, at: Date())
        try? modelContext.save()
    }

    @MainActor
    private func renderShareImage() {
        let card = ShareSessionCardView(
            muscleGroups: route.muscleGroupRaws,
            totalSeconds: route.totalSeconds,
            streak: profile?.stretchStreak ?? 0
        )
        let renderer = ImageRenderer(content: card.frame(width: 340))
        renderer.scale = UIScreen.main.scale
        shareImage = renderer.uiImage
    }
}

private struct ShareSessionCardView: View {
    let muscleGroups: [String]
    let totalSeconds: Int
    let streak: Int

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.bfGradient)
                .frame(height: 6)

            Text("Body Fix")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.bfTextPrimary)

            Text(dateString)
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextTertiary)

            FlowPillsView(labels: muscleGroups.map { raw in
                MuscleGroup(rawValue: raw)?.displayName ?? raw.capitalized
            })

            HStack {
                Text("Time: \(max(1, totalSeconds / 60)) min")
                Spacer()
                Text("Streak: \(streak)d")
            }
            .font(Typography.caption)
            .foregroundStyle(Color.bfTextSecondary)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.bfCard))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.bfBorder))
    }
}

private struct FlowPillsView: View {
    let labels: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(labels.chunked(into: 2).enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, label in
                        Text(label)
                            .font(Typography.badgeMono)
                            .foregroundStyle(Color.bfMint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.bfBlue.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0 ..< Swift.min($0 + size, count)]) }
    }
}

enum StreakUpdater {
    static func applySessionCompletion(to profile: UserProfile, at date: Date) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        if let last = profile.lastStretchActivityDate {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) {
                return
            }
            let days = cal.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if days == 1 {
                profile.stretchStreak += 1
                if profile.stretchStreak % 7 == 0, profile.stretchStreak > 0 {
                    HapticManager.shared.success()
                }
            } else if days > 1 {
                profile.stretchStreak = 1
            }
        } else {
            profile.stretchStreak = 1
        }
        profile.lastStretchActivityDate = date
    }
}
