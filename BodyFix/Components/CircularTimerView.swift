import SwiftUI

struct CircularTimerView: View {
    // TODO: Implement — reusable circular countdown timer component

    let totalSeconds: Int
    let remainingSeconds: Int

    var body: some View {
        Text("\(remainingSeconds)")
    }
}

#Preview {
    CircularTimerView(totalSeconds: 30, remainingSeconds: 15)
}
