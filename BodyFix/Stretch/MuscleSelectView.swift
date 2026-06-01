import SwiftUI

struct MuscleSelectView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(TabBarVisibility.self) private var tabBarVisibility
    @State private var selectedMuscles: Set<MuscleGroup> = []

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Where does it hurt?")
                        .font(Typography.screenTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    Text("Select the areas you want to stretch")
                        .font(Typography.screenSubtitle)
                        .foregroundStyle(Color.bfTextTertiary)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(MuscleGroup.allCases) { group in
                            MuscleCardView(
                                group: group,
                                isSelected: selectedMuscles.contains(group)
                            ) {
                                HapticManager.shared.selection()
                                if selectedMuscles.contains(group) {
                                    selectedMuscles.remove(group)
                                } else {
                                    selectedMuscles.insert(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, selectedMuscles.isEmpty ? 24 : 120)
                }
            }

            if !selectedMuscles.isEmpty {
                VStack(spacing: 0) {
                    Button {
                        HapticManager.shared.lightImpact()
                        path.append(StretchListRoute(muscles: selectedMuscles, perGroup: 3))
                    } label: {
                        Text("View \(selectedMuscles.count * 3) Stretches →")
                            .font(Typography.primaryCta)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(.bfGradient))
                            .shadow(color: Color(hex: "#5EEAD4").opacity(0.3), radius: 12, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: selectedMuscles.isEmpty)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticManager.shared.softImpact()
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bfTextPrimary)
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.bfSurfaceElevated.opacity(0.96))
                                .shadow(color: Color.black.opacity(0.12), radius: 12, y: 5)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.bfBorder.opacity(0.65), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear { tabBarVisibility.suppressTabBar() }
        .onDisappear { tabBarVisibility.restoreTabBar() }
    }
}
