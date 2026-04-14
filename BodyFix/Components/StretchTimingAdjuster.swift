import SwiftUI

struct StretchTimingAdjuster: View {
    let valueText: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            adjustButton(systemName: "minus", action: onDecrease)

            Text(valueText)
                .font(Typography.homeMeta)
                .foregroundStyle(Color.bfMint)
                .frame(minWidth: 42)

            adjustButton(systemName: "plus", action: onIncrease)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.bfSurfaceMuted))
    }

    private func adjustButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.bfTextSecondary)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.white.opacity(0.96)))
        }
        .buttonStyle(.plain)
    }
}
