import SwiftUI

struct StretchListView: View {
    var region: BodyRegion

    // TODO: Implement — shows 3 stretch cards for selected body region

    var body: some View {
        ZStack {
            Color.bfNavy.ignoresSafeArea()
            Text(region.displayName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .navigationTitle(region.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StretchListView(region: .lowerBack)
    }
}
