import SwiftUI

struct GradientButton: View {
    let title: String
    var showShadow: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.primaryCta)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.bfGradient))
                .if(showShadow) { view in
                    view.shadow(color: Color.bfAccent.opacity(0.24), radius: 12, y: 4)
                }
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
