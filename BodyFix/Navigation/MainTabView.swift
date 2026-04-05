import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let tabs = AppTab.allCases

    var body: some View {
        TabView(selection: $selectedTab) {
            StretchTabRoot(selectedTab: $selectedTab)
                .tag(AppTab.stretch.rawValue)

            WorkoutLogView(selectedTab: $selectedTab)
                .tag(AppTab.workoutLog.rawValue)

            CoachView()
                .tag(AppTab.coach.rawValue)

            SettingsView()
                .tag(AppTab.settings.rawValue)
        }
        .toolbar(.hidden, for: .tabBar)
        .tint(Color.bfMint)
        .background(Color.bfBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BodyFixTabBar(selectedTab: $selectedTab, tabs: tabs)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 6)
        }
    }
}

private enum AppTab: Int, CaseIterable {
    case stretch
    case workoutLog
    case coach
    case settings

    var title: String {
        switch self {
        case .stretch: return "Stretch"
        case .workoutLog: return "Workout Log"
        case .coach: return "AI Coach"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .stretch: return "figure.flexibility"
        case .workoutLog: return "list.clipboard"
        case .coach: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }
}

private struct BodyFixTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [AppTab]

    var body: some View {
        GeometryReader { proxy in
            let horizontalInset: CGFloat = 8
            let verticalInset: CGFloat = 8
            let laneWidth = (proxy.size.width - (horizontalInset * 2)) / CGFloat(max(tabs.count, 1))
            let highlightWidth = max(laneWidth - 12, 44)
            let highlightHeight = max(proxy.size.height - (verticalInset * 2) - 2, 42)
            let highlightX = horizontalInset + (laneWidth * CGFloat(selectedTab)) + (laneWidth / 2)

            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.bfSurfaceElevated.opacity(0.98))

                Capsule(style: .continuous)
                    .fill(Color.bfHeroSurface.opacity(0.14))
                    .frame(width: highlightWidth, height: highlightHeight)
                    .position(x: highlightX, y: proxy.size.height / 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.84), value: selectedTab)

                HStack(spacing: 0) {
                    ForEach(tabs, id: \.rawValue) { tab in
                        let isSelected = selectedTab == tab.rawValue

                        Button {
                            HapticManager.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                                selectedTab = tab.rawValue
                            }
                        } label: {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: isSelected ? .bold : .semibold))
                                .foregroundStyle(isSelected ? Color.bfHeroSurface : Color.bfTextMuted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tab.title)
                        .accessibilityValue(isSelected ? "Selected" : "")
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.vertical, verticalInset)
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.bfBorder.opacity(0.68), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
        }
        .frame(height: 70)
    }
}

private struct StretchTabRoot: View {
    @Binding var selectedTab: Int
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path, selectedTab: $selectedTab)
                .navigationDestination(for: MusclePickerRoute.self) { _ in
                    MuscleSelectView(path: $path)
                }
                .navigationDestination(for: StretchListRoute.self) { route in
                    StretchListView(
                        selectedMuscles: route.muscles,
                        path: $path,
                        perGroup: route.perGroup,
                        title: route.title
                    )
                }
                .navigationDestination(for: RoutineStretchListRoute.self) { route in
                    RoutineStretchListView(route: route, path: $path)
                }
                .navigationDestination(for: SeriesDetailRoute.self) { route in
                    SeriesDetailView(route: route, path: $path)
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
