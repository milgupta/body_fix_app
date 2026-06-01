import SwiftUI

struct OnboardingMultiSelectCard: View {
    let title: String
    var emoji: String = ""
    let isSelected: Bool
    var canToggle: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            if canToggle {
                HapticManager.shared.selection()
            }
            action()
        } label: {
            HStack(spacing: 14) {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.18) : Color.bfSurfaceMuted)
                        )
                }
                Text(title)
                    .font(Typography.optionText)
                    .foregroundStyle(isSelected ? Color.white : Color.bfTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "plus.circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.bfTextDisabled)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.bfGradient) : AnyShapeStyle(Color.bfSurfaceElevated))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.bfBorder.opacity(0.78), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.025), radius: isSelected ? 14 : 8, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        VStack(spacing: 12) {
            OnboardingMultiSelectCard(title: "Neck", emoji: "🦴", isSelected: true) {}
            OnboardingMultiSelectCard(title: "Lower Back", emoji: "⚡", isSelected: false) {}
            OnboardingMultiSelectCard(title: "Hips", emoji: "🦵", isSelected: true) {}
        }
        .padding()
    }
}
