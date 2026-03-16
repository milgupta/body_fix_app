import SwiftUI

struct BodyRegionPillsView: View {
    @Binding var selectedAngle: CameraAngle

    var body: some View {
        HStack(spacing: 6) {
            ForEach(CameraAngle.allCases, id: \.self) { angle in
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedAngle = angle
                    }
                } label: {
                    Text(angle.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedAngle == angle ? Color(red: 10/255, green: 22/255, blue: 40/255) : .bfTextSecondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedAngle == angle
                                      ? AnyShapeStyle(.bfSelectionGradient)
                                      : AnyShapeStyle(Color.bfCardDarker))
                        }
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: selectedAngle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bfCardDark)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        BodyRegionPillsView(selectedAngle: .constant(.front))
    }
}
