import SwiftUI

struct OnboardingHeroPreview: View {
    private let featuredIds = ["posture_reset", "desk_relief", "sleep_wind_down"]

    private var routines: [Routine] {
        featuredIds.compactMap { StretchDatabase.routine(id: $0) }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .fill(Color.white.opacity(0.34))
                .frame(width: 246, height: 512)
                .blur(radius: 18)
                .offset(y: 22)

            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.white)
                .frame(width: 244, height: 508)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 30, y: 18)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    if let heroRoutine = routines.first {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(heroRoutine.durationLabel)
                                .font(Typography.badgeMono)
                                .foregroundStyle(Color.white.opacity(0.82))

                            Text(heroRoutine.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)

                            Text("A focused reset for posture, pain, and everyday stiffness.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.76))
                                .lineLimit(2)

                            HStack(spacing: 10) {
                                ForEach(routines.prefix(3), id: \.id) { routine in
                                    BodyFixThumbnailView(routine: routine, size: 46, isFeatured: true)
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(LinearGradient.bfHeroGradient)
                        )
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.bfTextMuted)
                        Text("Search for a stretch or routine")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.bfTextMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.bfSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.bfBorder.opacity(0.9), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("RECOMMENDED FOR YOU")
                            .font(Typography.timerLabelSmall)
                            .tracking(1.6)
                            .foregroundStyle(Color.bfTextMuted)

                        HStack(spacing: 10) {
                            ForEach(routines.dropFirst().prefix(2), id: \.id) { routine in
                                VStack(alignment: .leading, spacing: 10) {
                                    BodyFixThumbnailView(routine: routine, size: 38)
                                    Text(routine.name)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(Color.bfTextPrimary)
                                        .lineLimit(2)
                                    Text(routine.shortDurationLabel)
                                        .font(Typography.timerLabelSmall)
                                        .foregroundStyle(Color.bfMint)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.bfSurfaceElevated)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
                                )
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 14) {
                        ForEach(["figure.flexibility", "list.clipboard", "sparkles", "gearshape.fill"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(icon == "figure.flexibility" ? Color.white : Color.white.opacity(0.72))
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(icon == "figure.flexibility" ? Color.bfHeroSurface.opacity(0.92) : Color.clear)
                                )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.bfHeroSurface.opacity(0.92))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 46)
                .padding(.bottom, 40)
            }
            .frame(width: 244, height: 508)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.bfSplashGradient.ignoresSafeArea()
        OnboardingHeroPreview()
    }
}
