import SwiftUI

struct MuscleCardView: View {
    let group: MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    ZStack {
                        // TODO: Replace with actual muscle group illustrations
                        Image(systemName: "figure.stand")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.bfTextTertiary)
                    }
                    .frame(width: geo.size.width * 0.4)

                    Text(group.displayName)
                        .font(Typography.muscleCardLabel)
                        .foregroundStyle(isSelected ? Color.bfTextPrimary : Color.bfTextSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 80)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bfCard)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.bfMint.opacity(0.125))
                        }
                    }
            )
            .overlay(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.bfBlue, Color.bfMint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.bfBorder, lineWidth: 1)
                    }
                }
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
