import SwiftUI

struct OnboardingOptionCard: View {
    let title: String
    var emoji: String = ""
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack(spacing: 14) {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 44, height: 44)
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
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.bfTextDisabled)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 78)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(.bfGradient) : AnyShapeStyle(Color.bfSurfaceElevated))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.bfBorder.opacity(0.78), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.1 : 0.035), radius: isSelected ? 16 : 10, y: 5)
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        VStack(spacing: 12) {
            OnboardingOptionCard(title: "Mostly sitting", emoji: "🪑", isSelected: false) {}
            OnboardingOptionCard(title: "Lightly active", emoji: "🚶", isSelected: true) {}
            OnboardingOptionCard(title: "Very active", emoji: "🏋️", isSelected: false) {}
        }
        .padding()
    }
}
