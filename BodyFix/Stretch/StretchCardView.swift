import SwiftUI

struct StretchCardView: View {
    let stretch: Stretch
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    BodyFixThumbnailView(stretch: stretch, size: 52)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .top) {
                            Text(stretch.name)
                                .font(Typography.stretchName)
                                .foregroundStyle(Color.bfTextPrimary)
                                .multilineTextAlignment(.leading)

                            Spacer(minLength: 8)

                            Text(stretch.durationBadgeText)
                                .font(Typography.badgeMono)
                                .foregroundStyle(Color.bfMint)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.bfBlue.opacity(0.08))
                                .clipShape(Capsule())
                        }

                    }
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green.opacity(0.85))
                        .frame(width: 6, height: 6)
                    Text("TAP TO START")
                        .font(Typography.tapHint)
                        .foregroundStyle(Color.bfTextMuted)
                }
                .padding(.top, 12)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.bfSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.bfBorder.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
