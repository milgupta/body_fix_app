import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var path: NavigationPath
    @Binding var selectedTab: Int
    @Query private var profiles: [UserProfile]
    @Query private var seriesProgress: [RoutineSeriesProgress]

    @State private var featuredIndex = 0
    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    private var profile: UserProfile? { profiles.first }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning," }
        if hour < 17 { return "Good afternoon," }
        return "Good evening,"
    }

    private var featured: [Routine] { StretchDatabase.featuredRoutines(for: profile) }
    private var browseAreas: [MuscleGroup] { StretchDatabase.browseAreas(prioritizing: profile) }
    private var recommended: [Routine] { StretchDatabase.recommendedRoutines(for: profile) }
    private var quick: [Routine] { StretchDatabase.quickRoutines() }
    private var series: [RoutineSeries] { StretchDatabase.seriesRoutines(prioritizing: profile) }
    private var injury: [Routine] { StretchDatabase.injuryRoutines(prioritizing: profile) }
    private var activity: [Routine] { StretchDatabase.activityRoutines() }
    private var searchResults: [SearchResult] { StretchDatabase.searchAll(searchText) }

    private var routineResults: [Routine] {
        searchResults.compactMap {
            if case let .routine(routine) = $0 { return routine }
            return nil
        }
    }

    private var stretchResults: [Stretch] {
        searchResults.compactMap {
            if case let .stretch(stretch) = $0 { return stretch }
            return nil
        }
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.bfPageBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 34) {
                        header

                        featuredSection

                        searchSection
                            .zIndex(5)

                        browseByAreaSection

                        routineGridSection(title: "RECOMMENDED FOR YOU", subtitle: nil, routines: recommended)

                        quickSection

                        seriesSection

                        routineGridSection(title: "INJURY & RECOVERY", subtitle: "Targeted relief", routines: injury)

                        routineGridSection(title: "BROWSE BY ACTIVITY", subtitle: nil, routines: activity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(proxy.safeAreaInsets.top + 16, 34))
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 96, 132))
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onTapGesture {
            searchFocused = false
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Color.bfTextMuted)

                Text(profile?.name.isEmpty == false ? profile?.name ?? "there" : "there")
                    .font(Typography.screenTitle)
                    .foregroundStyle(Color.bfTextPrimary)

                Text("Let’s keep today feeling loose and easy.")
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextTertiary)
            }

            Spacer()

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("\(profile?.stretchStreak ?? 0)")
                }
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfMint)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.bfSurfaceElevated))
                .overlay(Capsule().stroke(Color.bfBorder.opacity(0.9), lineWidth: 1))

                Button {
                    HapticManager.shared.lightImpact()
                    selectedTab = 3
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bfTextMuted)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.bfSurfaceElevated))
                        .overlay(Circle().stroke(Color.bfBorder.opacity(0.9), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            TabView(selection: $featuredIndex) {
                ForEach(Array(featured.enumerated()), id: \.element.id) { index, routine in
                    Button {
                        HapticManager.shared.mediumImpact()
                        path.append(RoutineStretchListRoute(routineId: routine.id))
                    } label: {
                        FeaturedRoutineCard(routine: routine)
                    }
                    .buttonStyle(.plain)
                    .tag(index)
                }
            }
            .frame(height: 252)
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 7) {
                ForEach(featured.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == featuredIndex ? Color.bfAccent : Color.bfBorder)
                        .frame(width: index == featuredIndex ? 16 : 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.22), value: featuredIndex)
        }
    }

    private var searchSection: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.bfTextMuted)

                TextField("Search for a stretch or routine", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.bfTextMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.bfSurfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(searchFocused ? Color.bfAccent.opacity(0.7) : Color.bfBorder.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 12, y: 6)

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                SearchResultsOverlay(
                    routineResults: routineResults,
                    stretchResults: stretchResults,
                    onRoutineTap: { routine in
                        HapticManager.shared.lightImpact()
                        searchText = ""
                        searchFocused = false
                        path.append(RoutineStretchListRoute(routineId: routine.id))
                    },
                    onStretchTap: { stretch in
                        HapticManager.shared.lightImpact()
                        searchText = ""
                        searchFocused = false
                        let ids = StretchDatabase.stretches(for: stretch.muscle ?? .neck).map(\.id)
                        let start = ids.firstIndex(of: stretch.id) ?? 0
                        path.append(StretchTimerRoute(stretchIds: ids, startIndex: start, routineName: stretch.name))
                    }
                )
                .padding(.top, 60)
            }
        }
    }

    private var browseByAreaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HomeSectionHeader(title: "BROWSE BY AREA")
                Spacer()
                Button("View all") {
                    HapticManager.shared.lightImpact()
                    path.append(MusclePickerRoute())
                }
                .font(Typography.metadataBadge)
                .foregroundStyle(Color.bfBlue)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(browseAreas, id: \.id) { group in
                        Button {
                            HapticManager.shared.lightImpact()
                            path.append(StretchListRoute(muscles: [group], perGroup: nil, title: group.displayName))
                        } label: {
                            AreaCard(group: group)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func routineGridSection(title: String, subtitle: String?, routines: [Routine]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: title)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextMuted)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(routines) { routine in
                    Button {
                        HapticManager.shared.mediumImpact()
                        path.append(RoutineStretchListRoute(routineId: routine.id))
                    } label: {
                        RoutineGridCard(routine: routine)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: "QUICK & EASY")
                Text("Under 5 min")
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(quick) { routine in
                        Button {
                            HapticManager.shared.lightImpact()
                            path.append(RoutineStretchListRoute(routineId: routine.id))
                        } label: {
                            QuickRoutineCard(routine: routine)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var seriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: "SERIES")
                Text("Progressive programs")
                    .font(Typography.caption)
                    .foregroundStyle(Color.bfTextMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(series) { item in
                        Button {
                            HapticManager.shared.mediumImpact()
                            path.append(SeriesDetailRoute(seriesId: item.id))
                        } label: {
                            SeriesCard(series: item, completedLevel: completedLevel(for: item.id))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func completedLevel(for seriesId: String) -> Int {
        seriesProgress.first(where: { $0.seriesId == seriesId })?.completedLevel ?? 0
    }
}

private struct HomeSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Typography.metadataBadge)
            .tracking(1.8)
            .foregroundStyle(Color.bfTextMuted)
    }
}

private struct FeaturedRoutineCard: View {
    let routine: Routine

    private var routineStretches: [Stretch] {
        StretchDatabase.stretches(for: routine)
    }

    private let circles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.69, 0.33, 56),
        (0.84, 0.33, 42),
        (0.61, 0.56, 46),
        (0.78, 0.56, 52),
        (0.70, 0.78, 44),
        (0.87, 0.74, 38),
    ]

    private let ghostCircles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.58, 0.18, 22),
        (0.92, 0.20, 26),
        (0.53, 0.46, 24),
        (0.93, 0.52, 28),
        (0.56, 0.82, 20),
        (0.93, 0.85, 24),
    ]

    private var supportLine: String {
        if routine.tags.contains("desk") { return "Gentle relief for long sitting days" }
        if routine.tags.contains("posture") { return "A simple reset to open and realign" }
        if routine.tags.contains("bedtime") || routine.tags.contains("relax") { return "Easy stretches to help you settle down" }
        if routine.tags.contains("recovery") { return "Recover without overthinking your routine" }
        if routine.tags.contains("flexibility") { return "Loosen up with a calm guided flow" }
        let names = routine.relatedMuscleGroups.prefix(2).compactMap { MuscleGroup(rawValue: $0)?.displayName.lowercased() }
        if names.count == 2 { return "Focused on \(names[0]) and \(names[1])" }
        if let first = names.first { return "Focused on your \(first)" }
        return "A simple routine to help you feel better fast"
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.bfHeroGradient)

                ForEach(Array(ghostCircles.enumerated()), id: \.offset) { _, item in
                    Circle()
                        .fill(Color.bfHeroGhostCircle.opacity(0.28))
                        .frame(width: item.2, height: item.2)
                        .position(x: size.width * item.0, y: size.height * item.1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(routine.durationLabel)
                        .font(Typography.badgeMono)
                        .foregroundStyle(Color.bfHeroTextSecondary)

                    Text(routine.name)
                        .font(.system(size: 27, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.bfHeroTextPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: size.width * 0.48, alignment: .leading)

                    Text(supportLine)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfHeroTextSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: size.width * 0.42, alignment: .leading)
                }
                .padding(.leading, 24)
                .padding(.top, 24)

                ForEach(Array(routineStretches.prefix(circles.count).enumerated()), id: \.offset) { index, stretch in
                    let item = circles[index]
                    BodyFixThumbnailView(stretch: stretch, size: item.2, isFeatured: true)
                        .position(x: size.width * item.0, y: size.height * item.1)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.16), radius: 24, y: 12)
        }
        .frame(height: 252)
    }
}

private struct AreaCard: View {
    let group: MuscleGroup

    var body: some View {
        VStack(spacing: 8) {
            BodyFixThumbnailView(muscleGroup: group, size: 50)

            Text(group.displayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.bfTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 84, height: 92)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 8, y: 3)
    }
}

private struct RoutineGridCard: View {
    let routine: Routine

    var body: some View {
        HStack(spacing: 10) {
            BodyFixThumbnailView(routine: routine, size: 42)

            VStack(alignment: .leading, spacing: 7) {
                Text(routine.name)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Color.bfTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(routine.durationLabel)
                    .font(Typography.metadataBadge)
                    .foregroundStyle(Color.bfMint)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 8, y: 3)
    }
}

private struct QuickRoutineCard: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            BodyFixThumbnailView(routine: routine, size: 34)

            Spacer(minLength: 0)

            Text(routine.name)
                .font(Typography.sectionTitle)
                .foregroundStyle(Color.bfTextPrimary)
                .lineLimit(2)

            Text(routine.shortDurationLabel)
                .font(Typography.timerLabelSmall)
                .foregroundStyle(Color.bfMint)
        }
        .padding(13)
        .frame(width: 150, height: 92, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 8, y: 3)
    }
}

private struct SeriesCard: View {
    let series: RoutineSeries
    let completedLevel: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(series.name)
                .font(Typography.controlLabel)
                .foregroundStyle(Color.bfTextPrimary)

            HStack(spacing: 10) {
                ForEach(1...3, id: \.self) { level in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(level <= completedLevel ? Color.bfMint : (level == completedLevel + 1 ? Color.bfBlue : Color.bfBorder))
                            .frame(width: 10, height: 10)
                        Text(level == 1 ? "I" : level == 2 ? "II" : "III")
                            .font(Typography.timerLabelSmall)
                            .foregroundStyle(Color.bfTextMuted)
                    }

                    if level < 3 {
                        Rectangle()
                            .fill(level < completedLevel ? Color.bfMint : Color.bfBorder)
                            .frame(width: 28, height: 2)
                    }
                }
            }

            Spacer()

            Text(series.difficultyLabel)
                .font(Typography.caption)
                .foregroundStyle(Color.bfTextMuted)
        }
        .padding(16)
        .frame(width: 200, height: 130, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 8, y: 3)
    }
}

private struct SearchResultsOverlay: View {
    let routineResults: [Routine]
    let stretchResults: [Stretch]
    let onRoutineTap: (Routine) -> Void
    let onStretchTap: (Stretch) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if routineResults.isEmpty && stretchResults.isEmpty {
                Text("No matches yet")
                    .font(Typography.sectionTitle)
                    .foregroundStyle(Color.bfTextMuted)
                    .padding(14)
            } else {
                if !routineResults.isEmpty {
                    sectionLabel("Routines")
                    ForEach(routineResults.prefix(5)) { routine in
                        resultRow(
                            title: routine.name,
                            subtitle: routine.durationLabel,
                            type: "Routine",
                            routine: routine,
                            stretch: routine.thumbnailStretchIds.compactMap { StretchDatabase.stretch(id: $0) }.first
                        ) {
                            onRoutineTap(routine)
                        }
                    }
                }

                if !stretchResults.isEmpty {
                    sectionLabel("Stretches")
                    ForEach(stretchResults.prefix(6)) { stretch in
                        resultRow(
                            title: stretch.name,
                            subtitle: stretch.durationBadgeText,
                            type: "Stretch",
                            stretch: stretch
                        ) {
                            onStretchTap(stretch)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.95), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, y: 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.timerLabelSmall)
            .foregroundStyle(Color.bfTextMuted)
            .padding(.horizontal, 14)
            .padding(.top, 4)
    }

    private func resultRow(
        title: String,
        subtitle: String,
        type: String,
        routine: Routine? = nil,
        stretch: Stretch?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let routine {
                    BodyFixThumbnailView(routine: routine, size: 32)
                } else {
                    BodyFixThumbnailView(stretch: stretch, size: 32)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Typography.sectionTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Color.bfTextMuted)
                }

                Spacer()

                Text(type)
                    .font(Typography.timerLabelSmall)
                    .foregroundStyle(Color.bfTextMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
