import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StretchTabRoot()
                .tabItem {
                    Label("Stretch", systemImage: "figure.flexibility")
                }
                .tag(0)

            WorkoutLogView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Workout Log", systemImage: "list.clipboard")
                }
                .tag(1)

            CoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "sparkles")
                }
                .tag(2)
        }
        .tint(Color.bfMint)
    }
}

private struct StretchTabRoot: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            MuscleSelectView(path: $path)
                .navigationDestination(for: StretchListRoute.self) { route in
                    StretchListView(selectedMuscles: route.muscles, path: $path)
                }
                .navigationDestination(for: StretchTimerRoute.self) { route in
                    StretchTimerView(route: route, path: $path)
                }
                .navigationDestination(for: SessionCompleteRoute.self) { route in
                    SessionCompleteView(route: route, path: $path)
                }
        }
    }
}

#Preview {
    MainTabView()
}
