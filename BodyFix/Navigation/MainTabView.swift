import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var tabBarVisibility = TabBarVisibility()
    private let tabs = AppTab.allCases

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent

            if !tabBarVisibility.isHidden {
                BodyFixTabBar(selectedTab: $selectedTab, tabs: tabs)
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .padding(.bottom, 0)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: tabBarVisibility.isHidden)
        .background(Color.bfBackground.ignoresSafeArea())
        .environment(tabBarVisibility)
    }

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            tabView(for: .stretch)
            tabView(for: .plan)
            tabView(for: .analytics)
            tabView(for: .workoutLog)
            tabView(for: .settings)
        }
        .tint(Color.bfMint)
    }

    @ViewBuilder
    private func tabView(for tab: AppTab) -> some View {
        Group {
            switch tab {
            case .stretch:
                StretchTabRoot(selectedTab: $selectedTab)
            case .plan:
                PersonalizedPlanTabRoot()
            case .analytics:
                AnalyticsTabRoot()
            case .workoutLog:
                SavedTabRoot(selectedTab: $selectedTab)
            case .settings:
                SettingsView()
            }
        }
        .opacity(selectedTab == tab.rawValue ? 1 : 0)
        .allowsHitTesting(selectedTab == tab.rawValue)
        .accessibilityHidden(selectedTab != tab.rawValue)
    }
}

private enum AppTab: Int, CaseIterable {
    case stretch
    case plan
    case analytics
    case workoutLog
    case settings

    var title: String {
        switch self {
        case .stretch: return "Stretch"
        case .plan: return "Your Plan"
        case .analytics: return "Analytics"
        case .workoutLog: return "Saved"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .stretch: return "figure.flexibility"
        case .plan: return "sparkles"
        case .analytics: return "chart.bar.fill"
        case .workoutLog: return "list.clipboard"
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
            let verticalInset: CGFloat = 7
            let laneWidth = (proxy.size.width - (horizontalInset * 2)) / CGFloat(max(tabs.count, 1))
            let highlightSize = min(max(laneWidth - 24, 36), 46)
            let highlightX = horizontalInset + (laneWidth * CGFloat(selectedTab)) + (laneWidth / 2)

            ZStack {
                Capsule(style: .continuous)
                    .fill(Color.bfTabBarFill)

                Circle()
                    .fill(Color.bfTabBarSpotlight)
                    .frame(width: highlightSize, height: highlightSize)
                    .overlay(
                        Circle()
                            .fill(Color.bfTabBarSpotlightCore)
                            .padding(8)
                    )
                    .blur(radius: 0.2)
                    .position(x: highlightX, y: proxy.size.height / 2)
                    .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectedTab)

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
                                .font(.system(size: 21, weight: isSelected ? .bold : .semibold))
                                .foregroundStyle(isSelected ? Color.white.opacity(0.96) : Color.white.opacity(0.58))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
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
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.bfTabBarBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
        }
        .frame(height: 64)
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
                .navigationDestination(for: PersonalizedPlanRoute.self) { _ in
                    PersonalizedPlanDetailView(path: $path)
                }
                .navigationDestination(for: PersonalizedPlanEditorRoute.self) { _ in
                    PersonalizedPlanEditorView()
                }
        }
    }
}

private struct PersonalizedPlanTabRoot: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            PersonalizedPlanDetailView(path: $path, showsBackButton: false)
                .navigationDestination(for: RoutineStretchListRoute.self) { route in
                    RoutineStretchListView(route: route, path: $path)
                }
                .navigationDestination(for: StretchTimerRoute.self) { route in
                    StretchTimerView(route: route, path: $path)
                }
                .navigationDestination(for: SessionCompleteRoute.self) { route in
                    SessionCompleteView(route: route, path: $path)
                }
                .navigationDestination(for: PersonalizedPlanEditorRoute.self) { _ in
                    PersonalizedPlanEditorView()
                }
        }
    }
}

private struct AnalyticsTabRoot: View {
    var body: some View {
        NavigationStack {
            AnalyticsView()
        }
    }
}

private struct SavedTabRoot: View {
    @Binding var selectedTab: Int
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WorkoutLogView(selectedTab: $selectedTab, path: $path)
                .navigationDestination(for: RoutineStretchListRoute.self) { route in
                    RoutineStretchListView(route: route, path: $path)
                }
                .navigationDestination(for: PersonalizedPlanRoute.self) { _ in
                    PersonalizedPlanDetailView(path: $path)
                }
                .navigationDestination(for: PersonalizedPlanEditorRoute.self) { _ in
                    PersonalizedPlanEditorView()
                }
                .navigationDestination(for: SavedPlanDetailRoute.self) { route in
                    SavedPlanDetailView(route: route, path: $path)
                }
                .navigationDestination(for: StretchTimerRoute.self) { route in
                    StretchTimerView(route: route, path: $path)
                }
        }
    }
}

#Preview {
    MainTabView()
}
