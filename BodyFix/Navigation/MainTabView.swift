import SwiftUI

struct MainTabView: View {
    // TODO: Implement — tab bar with two tabs: Body Map (home) and Workout Log

    var body: some View {
        TabView {
            BodyMapView()
                .tabItem {
                    Label("Body Map", systemImage: "figure.stand")
                }

            WorkoutLogView()
                .tabItem {
                    Label("Workout Log", systemImage: "list.clipboard")
                }
        }
    }
}

#Preview {
    MainTabView()
}
