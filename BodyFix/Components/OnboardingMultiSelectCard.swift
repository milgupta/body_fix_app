import SwiftUI

struct OnboardingMultiSelectCard: View {
    let title: String
    var emoji: String = ""
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            HStack(spacing: 12) {
                if !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 22))
                }
                Text(title)
                    .font(Typography.optionText)
                    .foregroundStyle(isSelected ? .bfTextPrimary : .bfTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.bfSelectionGradient)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.bfCardDark)
                    }
                }
            )
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
