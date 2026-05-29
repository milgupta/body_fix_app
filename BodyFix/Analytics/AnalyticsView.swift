import SwiftUI
import SwiftData
import UIKit

struct AnalyticsView: View {
    @Query private var profiles: [UserProfile]
    @Query(sort: \StretchSession.date, order: .reverse) private var sessions: [StretchSession]

    private let gridColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var snapshot: AnalyticsSnapshot {
        AnalyticsCalculator.snapshot(profile: profiles.first, sessions: sessions)
    }

    private var scoreProgress: Double {
        Double(snapshot.flexometerScore) / 100
    }

    private var scoreColor: Color {
        Color.interpolate(from: Color.bfBlue, to: Color.bfSliderGreen, progress: scoreProgress)
    }

    var body: some View {
        ZStack {
            Color.bfPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    heroCard
                    statsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 128)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analytics")
                .font(Typography.screenTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("A simple view of your consistency, momentum, and weekly movement.")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("FLEXOMETER")
                        .font(Typography.badgeMono)
                        .foregroundStyle(Color.bfTextMuted)

                    Text("Your weekly momentum")
                        .font(Typography.homeCardTitleCompact)
                        .foregroundStyle(Color.bfTextPrimary)
                }

                Spacer()

                Text("Last 7 days")
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.bfBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.bfBlue.opacity(0.10)))
            }

            ZStack {
                FlexometerArc(progress: 1)
                    .stroke(Color.bfBorder.opacity(0.65), style: StrokeStyle(lineWidth: 24, lineCap: .round))

                FlexometerArc(progress: scoreProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.bfBlue.opacity(0.55), scoreColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 24, lineCap: .round)
                    )

                Text("\(snapshot.flexometerScore)%")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bfTextPrimary)
                    .padding(.horizontal, 16)
            }
            .frame(height: 224)
            .padding(.top, 4)

            Text(snapshot.supportMessage)
                .font(Typography.homeSupport)
                .foregroundStyle(Color.bfTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your stats")
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)

            LazyVGrid(columns: gridColumns, spacing: 14) {
                AnalyticsStatCard(
                    title: "Current streak",
                    value: "\(snapshot.currentStreak)",
                    detail: snapshot.currentStreak == 1 ? "day" : "days",
                    accent: scoreColor
                )
                AnalyticsStatCard(
                    title: "Longest streak",
                    value: "\(snapshot.longestStreak)",
                    detail: snapshot.longestStreak == 1 ? "day" : "days",
                    accent: Color.bfBlue
                )
                AnalyticsStatCard(
                    title: "Stretches this week",
                    value: "\(snapshot.completedStretchesThisWeek)",
                    detail: snapshot.completedStretchesThisWeek == 1 ? "stretch" : "stretches",
                    accent: Color.bfAccentWarm
                )
                AnalyticsStatCard(
                    title: "Minutes this week",
                    value: "\(snapshot.minutesThisWeek)",
                    detail: snapshot.minutesThisWeek == 1 ? "minute" : "minutes",
                    accent: Color.bfMint
                )
            }
        }
    }
}

private struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let detail: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(Typography.badgeMono)
                .foregroundStyle(Color.bfTextMuted)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.bfTextPrimary)

                Text(detail)
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextTertiary)
            }

            Capsule()
                .fill(accent.opacity(0.20))
                .frame(width: 48, height: 8)
                .overlay(
                    Capsule()
                        .fill(accent)
                        .frame(width: 26, height: 8)
                )
        }
        .frame(maxWidth: .infinity, minHeight: 144, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)
    }
}

private struct FlexometerArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clamped = max(0, min(progress, 1))
        let startAngle = Angle(degrees: 150)
        let endAngle = Angle(degrees: 390)
        let sweep = endAngle.degrees - startAngle.degrees
        let radius = min(rect.width, rect.height) / 2 - 14
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: Angle(degrees: startAngle.degrees + (sweep * clamped)),
            clockwise: false
        )
        return path
    }
}

private extension Color {
    static func interpolate(from start: Color, to end: Color, progress: Double) -> Color {
        let clamped = max(0, min(progress, 1))
        let fromComponents = UIColor(start).rgbaComponents
        let toComponents = UIColor(end).rgbaComponents

        return Color(
            red: fromComponents.red + (toComponents.red - fromComponents.red) * clamped,
            green: fromComponents.green + (toComponents.green - fromComponents.green) * clamped,
            blue: fromComponents.blue + (toComponents.blue - fromComponents.blue) * clamped,
            opacity: fromComponents.alpha + (toComponents.alpha - fromComponents.alpha) * clamped
        )
    }
}

private extension UIColor {
    var rgbaComponents: (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(
            for: [
                UserProfile.self,
                PersonalizedPlan.self,
                StretchSession.self,
                RoutineSeriesProgress.self,
                SavedRoutine.self,
                StretchTimingOverride.self,
            ],
            inMemory: true
        )
}
