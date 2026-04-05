import SwiftUI
import SwiftData

struct WorkoutLogView: View {
    @Binding var selectedTab: Int
    @Query(sort: \StretchSession.date, order: .reverse) private var sessions: [StretchSession]
    @Query private var profiles: [UserProfile]

    private var streak: Int {
        profiles.first?.stretchStreak ?? 0
    }

    var body: some View {
        ZStack {
            Color.bfBackground.ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Workout Log")
                            .font(Typography.screenTitle)
                            .foregroundStyle(Color.bfTextPrimary)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        streakBanner
                            .padding(.horizontal, 20)

                        ForEach(sessions) { session in
                            WorkoutLogEntryView(session: session)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var streakBanner: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("🔥")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 4) {
                if streak == 0 {
                    Text("Start your streak today!")
                        .font(Typography.cardTitle)
                        .foregroundStyle(Color.bfMint)
                    Text("Complete a stretch routine to begin.")
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.bfTextTertiary)
                } else {
                    Text("\(streak) day streak")
                        .font(Typography.cardTitle)
                        .foregroundStyle(Color.bfMint)
                    Text("Keep it going!")
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.bfTextTertiary)
                }
            }
            Spacer()
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.bfSurfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.bfBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Text("🧘")
                .font(.system(size: 56))
            Text("No stretches yet")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextMuted)
            Button {
                HapticManager.shared.mediumImpact()
                selectedTab = 0
            } label: {
                Text("Start your first routine")
                    .font(Typography.primaryCta)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.bfGradient))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    WorkoutLogView(selectedTab: .constant(0))
        .modelContainer(for: [StretchSession.self, UserProfile.self], inMemory: true)
}
