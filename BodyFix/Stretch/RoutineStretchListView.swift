import SwiftUI

struct RoutineStretchListView: View {
    let route: RoutineStretchListRoute
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss

    private var routine: Routine? {
        StretchDatabase.routine(id: route.routineId)
    }

    private var stretches: [Stretch] {
        guard let routine else { return [] }
        return StretchDatabase.stretches(for: routine)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bfBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    ForEach(stretches) { stretch in
                        StretchCardView(stretch: stretch) {
                            HapticManager.shared.mediumImpact()
                            let ids = stretches.map(\.id)
                            if let idx = ids.firstIndex(of: stretch.id) {
                                path.append(
                                    StretchTimerRoute(
                                        stretchIds: ids,
                                        startIndex: idx,
                                        routineName: routine?.name,
                                        seriesId: routine?.seriesId,
                                        seriesLevel: routine?.level
                                    )
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, stretches.isEmpty ? 40 : 120)
            }

            if !stretches.isEmpty {
                GradientButton(title: "Start Routine") {
                    HapticManager.shared.heavyImpact()
                    path.append(
                        StretchTimerRoute(
                            stretchIds: stretches.map(\.id),
                            startIndex: 0,
                            routineName: routine?.name,
                            seriesId: routine?.seriesId,
                            seriesLevel: routine?.level
                        )
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
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
        VStack(alignment: .leading, spacing: 14) {
            if let routine {
                BodyFixThumbnailView(routine: routine, size: 72)

                Text(routine.durationLabel)
                    .font(Typography.badgeMono)
                    .foregroundStyle(Color.bfMint)

                Text(routine.name)
                    .font(Typography.screenTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                Text("\(stretches.count) stretches")
                    .font(Typography.screenSubtitle)
                    .foregroundStyle(Color.bfTextTertiary)
            } else {
                Text("Routine unavailable")
                    .font(Typography.screenTitle)
                    .foregroundStyle(Color.bfTextPrimary)
            }
        }
        .padding(.top, 12)
    }
}
