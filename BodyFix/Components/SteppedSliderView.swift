import SwiftUI

struct SteppedSliderView: View {
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...5
    var labels: [Int: String] = [1: "Relaxed", 3: "Moderate", 5: "Very Tight"]
    var showValueLabel: Bool = true

    private let trackHeight: CGFloat = 8
    private let thumbSize: CGFloat = 28

    @State private var isDragging = false
    @State private var lastNotchValue: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            if showValueLabel {
                Text("\(value)")
                    .font(Typography.sliderValue)
                    .foregroundStyle(.bfTextPrimary)

                if let label = labels[value] {
                    Text(label)
                        .font(Typography.optionText)
                        .foregroundStyle(.bfTextSecondary)
                }
            }

            GeometryReader { geo in
                let totalWidth = geo.size.width - thumbSize
                let stepWidth = totalWidth / CGFloat(range.count - 1)
                let thumbX = CGFloat(value - range.lowerBound) * stepWidth

                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(
                            LinearGradient(
                                colors: [.bfMint, .bfSliderGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: trackHeight)
                        .padding(.horizontal, thumbSize / 2)

                    // Thumb
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .offset(x: thumbX)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { drag in
                                    if !isDragging {
                                        isDragging = true
                                        lastNotchValue = value
                                    }
                                    let newX = drag.location.x - thumbSize / 2
                                    let clamped = max(0, min(totalWidth, newX))
                                    let step = Int(round(clamped / stepWidth))
                                    let newValue = range.lowerBound + step

                                    if newValue != lastNotchValue {
                                        HapticManager.shared.selection()
                                        lastNotchValue = newValue
                                    }
                                    value = max(range.lowerBound, min(range.upperBound, newValue))
                                }
                                .onEnded { _ in
                                    isDragging = false
                                    HapticManager.shared.lightImpact()
                                }
                        )
                }
                .frame(height: thumbSize)

                // Min/Max labels
                HStack {
                    Text("\(range.lowerBound)")
                        .font(Typography.caption)
                        .foregroundStyle(.bfTextSecondary)
                    Spacer()
                    Text("\(range.upperBound)")
                        .font(Typography.caption)
                        .foregroundStyle(.bfTextSecondary)
                }
                .padding(.horizontal, thumbSize / 2)
                .offset(y: thumbSize + 4)
            }
            .frame(height: thumbSize + 24)
        }
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        SteppedSliderView(value: .constant(3))
            .padding(40)
    }
}
