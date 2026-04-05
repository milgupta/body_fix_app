import SwiftUI
import SwiftData

struct OnboardingPlanPreviewView: View {
    @Environment(OnboardingViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showContent = false

    private var previewStretches: [Stretch] {
        let groups = muscleGroupsFromPainAreas()
        if groups.isEmpty {
            return Array(StretchDatabase.loadAll().prefix(3))
        }
        let list = StretchDatabase.stretches(for: groups, perGroup: 1)
        return Array(list.prefix(3))
    }

    private func muscleGroupsFromPainAreas() -> Set<MuscleGroup> {
        var set = Set<MuscleGroup>()
        for area in viewModel.selectedPainAreas {
            switch area {
            case .ankles:
                set.insert(.calves)
            case .wholeBody:
                break
            default:
                if let g = MuscleGroup(rawValue: area.rawValue) {
                    set.insert(g)
                }
            }
        }
        return set
    }

    private var totalDuration: Int {
        previewStretches.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    HapticManager.shared.softImpact()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        viewModel.goBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Typography.navIcon)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)

            Text("Your first Body Fix plan")
                .font(Typography.splashTitle)
                .foregroundStyle(.bfTextPrimary)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 8)

            Text("A simple routine built around what you told us.")
                .font(Typography.subtitle)
                .foregroundStyle(.bfTextSecondary)
                .padding(.horizontal, 20)
                .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 16)

            HStack(spacing: 10) {
                previewBadge(title: "\(previewStretches.count) stretches")
                previewBadge(title: "\(totalDuration / 60)m \(totalDuration % 60)s")
                previewBadge(title: "Start today")
            }
            .padding(.horizontal, 20)
            .opacity(showContent ? 1.0 : 0)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                ForEach(Array(previewStretches.enumerated()), id: \.element.id) { index, stretch in
                    HStack(spacing: 16) {
                        BodyFixThumbnailView(stretch: stretch, size: 52)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(stretch.name)
                                .font(Typography.optionText)
                                .foregroundStyle(.bfTextPrimary)

                            Text("Step \(index + 1) · \(stretch.duration)s · \(stretch.repScheme)")
                                .font(Typography.caption)
                                .foregroundStyle(.bfTextSecondary)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.bfSurfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.bfBorder.opacity(0.75), lineWidth: 1)
                            )
                    )
                    .opacity(showContent ? 1.0 : 0)
                    .animation(
                        .easeOut(duration: 0.5).delay(Double(index) * 0.15),
                        value: showContent
                    )
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            OnboardingContinueButton(label: "Start My Plan") {
                HapticManager.shared.success()
                viewModel.saveProfile(to: modelContext)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    private func previewBadge(title: String) -> some View {
        Text(title)
            .font(Typography.caption)
            .foregroundStyle(.bfAccent)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.bfSurfaceMuted)
            )
    }
}

#Preview {
    ZStack {
        Color.bfNavy.ignoresSafeArea()
        OnboardingPlanPreviewView()
    }
    .environment(OnboardingViewModel())
    .modelContainer(for: [UserProfile.self, StretchSession.self], inMemory: true)
}
