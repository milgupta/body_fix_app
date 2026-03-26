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
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(.bfGradient))
                .if(showShadow) { view in
                    view.shadow(color: Color(hex: "#5EEAD4").opacity(0.3), radius: 12, y: 4)
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
