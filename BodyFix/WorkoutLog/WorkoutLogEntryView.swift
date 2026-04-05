import SwiftUI
import SwiftData

struct WorkoutLogEntryView: View {
    let session: StretchSession
    @State private var expanded = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                HapticManager.shared.lightImpact()
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(Self.dateFormatter.string(from: session.date))
                            .font(Typography.stretchName)
                            .foregroundStyle(Color.bfTextPrimary)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.bfTextMuted)
                    }

                    HStack(spacing: 6) {
                        ForEach(session.muscleGroups, id: \.self) { raw in
                            Text(MuscleGroup(rawValue: raw)?.displayName ?? raw)
                                .font(Typography.badgeMono)
                                .foregroundStyle(Color.bfMint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.bfBlue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    HStack {
                        Text(formatDuration(session.totalDuration))
                            .font(Typography.caption)
                            .foregroundStyle(Color.bfTextTertiary)
                        Spacer()
                        Text("\(session.stretchCount) stretches")
                            .font(Typography.caption)
                            .foregroundStyle(Color.bfTextTertiary)
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(Color.bfBorder)
                    ForEach(session.stretchNames, id: \.self) { name in
                        Text("• \(name)")
                            .font(Typography.stretchDescription)
                            .foregroundStyle(Color.bfTextSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.bfSurfaceElevated))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.bfBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.03), radius: 10, y: 4)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 { return "\(m) min \(s)s" }
        return "\(s)s"
    }
}
