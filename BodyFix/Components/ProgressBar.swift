import SwiftUI

struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.bfCardDark)
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.bfProgressGradient)
                    .frame(width: max(0, geo.size.width * progress), height: 8)
                    .animation(.easeInOut(duration: 0.35), value: progress)
            }
        }
        .frame(height: 8)
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        VStack(spacing: 20) {
            ProgressBar(progress: 0.25)
            ProgressBar(progress: 0.5)
            ProgressBar(progress: 0.75)
        }
        .padding()
    }
}
