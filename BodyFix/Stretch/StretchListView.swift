import SwiftUI

struct StretchListView: View {
    let selectedMuscles: Set<MuscleGroup>
    @Binding var path: NavigationPath
    var perGroup: Int? = 3
    var title: String? = nil
    @Environment(\.dismiss) private var dismiss

    private var sections: [(MuscleGroup, [Stretch])] {
        StretchDatabase.groupedStretches(for: selectedMuscles, perGroup: perGroup)
    }

    private var flatStretches: [Stretch] {
        sections.flatMap(\.1)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    ForEach(sections, id: \.0) { group, stretches in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.displayName)
                                .font(Typography.screenSubtitle)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.bfTextTertiary)
                                .padding(.horizontal, 4)

                            ForEach(stretches) { stretch in
                                StretchCardView(stretch: stretch) {
                                    HapticManager.shared.mediumImpact()
                                    let ids = flatStretches.map(\.id)
                                    if let idx = ids.firstIndex(of: stretch.id) {
                                        path.append(StretchTimerRoute(stretchIds: ids, startIndex: idx))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 168)
            }

            if !flatStretches.isEmpty {
                VStack {
                    GradientButton(title: "Start Routine →", showShadow: true) {
                        HapticManager.shared.heavyImpact()
                        let ids = flatStretches.map(\.id)
                        path.append(StretchTimerRoute(stretchIds: ids, startIndex: 0))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 72)
                }
                .background(
                    LinearGradient(
                        colors: [Color.bfBackground.opacity(0), Color.bfBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .offset(y: -40)
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    HapticManager.shared.mediumImpact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.navIcon)
                        .foregroundStyle(Color.bfMint)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title ?? "Your Stretches")
                .font(Typography.navTitle)
                .foregroundStyle(Color.bfTextPrimary)

            Text("\(flatStretches.count) stretches for \(selectedMuscles.count) area\(selectedMuscles.count == 1 ? "" : "s")")
                .font(Typography.screenSubtitle)
                .foregroundStyle(Color.bfTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}
