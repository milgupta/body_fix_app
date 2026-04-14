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
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    private var profile: UserProfile? { profiles.first }

    private let greeting = "Welcome back,"

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
                    VStack(alignment: .leading, spacing: 38) {
                        header
                        featuredSection
                        searchSection
                            .zIndex(5)
                        browseByAreaSection
                        routineCarouselSection(
                            title: "Recommended",
                            subtitle: "Start with what feels good today",
                            routines: recommended,
                            style: .featured
                        )
                        quickSection
                        seriesSection
                        routineGridSection(title: "Browse by activity", subtitle: nil, routines: activity)
                        routineGridSection(title: "Injury & recovery", subtitle: "Targeted relief", routines: injury)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, max(proxy.safeAreaInsets.top - 18, 4))
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 98, 138))
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
                    .font(Typography.homeGreeting)
                    .foregroundStyle(Color.bfTextMuted)

                Text(profile?.name.isEmpty == false ? profile?.name ?? "there" : "there")
                    .font(Typography.homeDisplayTitle)
                    .foregroundStyle(Color.bfTextPrimary)
                    .lineSpacing(-1)

                Text("Let’s keep today feeling loose and easy.")
                    .font(Typography.homeSupport)
                    .foregroundStyle(Color.bfTextTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                    Text("\(profile?.stretchStreak ?? 0)")
                }
                .font(Typography.homeMeta)
                .foregroundStyle(Color.bfMint)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Capsule().fill(Color.bfSurfaceElevated))
                .overlay(Capsule().stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))

                Button {
                    HapticManager.shared.lightImpact()
                    selectedTab = 4
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.bfTextMuted)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(Color.bfSurfaceElevated))
                        .overlay(Circle().stroke(Color.bfBorder.opacity(0.55), lineWidth: 1))
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
                        .frame(width: index == featuredIndex ? 18 : 7, height: 7)
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
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.bfSurfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(searchFocused ? Color.bfAccent.opacity(0.45) : Color.bfBorder.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)

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
                .padding(.top, 62)
            }
        }
    }

    private var browseByAreaSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HomeSectionHeader(title: "Browse by area")
                Spacer()
                Button("View all") {
                    HapticManager.shared.lightImpact()
                    path.append(MusclePickerRoute())
                }
                .font(Typography.homeMeta)
                .foregroundStyle(Color.bfBlue)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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

    private func routineCarouselSection(title: String, subtitle: String?, routines: [Routine], style: HomeRoutineCardStyle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: title)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.homeSupport)
                        .foregroundStyle(Color.bfTextMuted)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(routines) { routine in
                        Button {
                            HapticManager.shared.mediumImpact()
                            path.append(RoutineStretchListRoute(routineId: routine.id))
                        } label: {
                            HomeRoutineCarouselCard(routine: routine, style: style)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 36)
                .padding(.vertical, 2)
            }
        }
    }

    private func routineGridSection(title: String, subtitle: String?, routines: [Routine]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: title)
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.homeSupport)
                        .foregroundStyle(Color.bfTextMuted)
                }
            }

            LazyVGrid(columns: gridColumns, spacing: 14) {
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: "Quick & easy")
                Text("Under 5 min")
                    .font(Typography.homeSupport)
                    .foregroundStyle(Color.bfTextMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HomeSectionHeader(title: "Series")
                Text("Progressive programs")
                    .font(Typography.homeSupport)
                    .foregroundStyle(Color.bfTextMuted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
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
                .padding(.trailing, 36)
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
            .font(Typography.homeSectionLabel)
            .foregroundStyle(Color.bfTextSecondary)
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
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(.bfHeroGradient)

                ForEach(Array(ghostCircles.enumerated()), id: \.offset) { _, item in
                    Circle()
                        .fill(Color.bfHeroGhostCircle.opacity(0.28))
                        .frame(width: item.2, height: item.2)
                        .position(x: size.width * item.0, y: size.height * item.1)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(routine.invitingDurationLabel)
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfHeroTextSecondary)

                    Text(routine.name)
                        .font(Typography.homeCardTitleLarge)
                        .foregroundStyle(Color.bfHeroTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(-1)
                        .frame(maxWidth: size.width * 0.5, alignment: .leading)

                    Text(supportLine)
                        .font(Typography.homeCardSupport)
                        .foregroundStyle(Color.bfHeroTextSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: size.width * 0.44, alignment: .leading)
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
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 20, y: 10)
        }
        .frame(height: 252)
    }
}

private struct AreaCard: View {
    let group: MuscleGroup

    var body: some View {
        VStack(spacing: 10) {
            BodyFixThumbnailView(muscleGroup: group, size: 52)

            Text(group.displayName)
                .font(Typography.homeMeta)
                .foregroundStyle(Color.bfTextSecondary)
                .lineLimit(1)
        }
        .frame(width: 96, height: 106)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.48), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.018), radius: 6, y: 2)
    }
}

private enum HomeRoutineCardStyle {
    case featured
}

private struct HomeRoutineCarouselCard: View {
    let routine: Routine
    let style: HomeRoutineCardStyle

    private static let warmPalettes: [[Color]] = [
        [Color(hex: "#FFF5E7"), Color(hex: "#F3E2C7")],
        [Color(hex: "#FFF4EC"), Color(hex: "#F5E4D6")],
    ]

    private static let coolPalettes: [[Color]] = [
        [Color(hex: "#EEF6FF"), Color(hex: "#DCEAF5")],
        [Color(hex: "#EEF4FF"), Color(hex: "#DFE9F9")],
    ]

    private static let calmPalettes: [[Color]] = [
        [Color(hex: "#F6EEFF"), Color(hex: "#E8DFF7")],
        [Color(hex: "#F7F0FF"), Color(hex: "#E7E0F6")],
    ]

    private static let freshPalettes: [[Color]] = [
        [Color(hex: "#F1FBF5"), Color(hex: "#DCEFE6")],
        [Color(hex: "#F4FAF1"), Color(hex: "#E3F0DD")],
    ]

    private static let neutralPalettes: [[Color]] = [
        [Color(hex: "#F7F5EF"), Color(hex: "#E8EDF4")],
        [Color(hex: "#F8F4F1"), Color(hex: "#E7ECEF")],
    ]

    private var accentPalette: [Color] {
        if routine.tags.contains("desk") || routine.tags.contains("posture") {
            return paletteVariant(from: Self.warmPalettes)
        }

        if routine.tags.contains("bedtime") || routine.tags.contains("relax") || routine.tags.contains("sleep") {
            return paletteVariant(from: Self.calmPalettes)
        }

        if routine.tags.contains("recovery") || routine.tags.contains("injury") {
            return paletteVariant(from: Self.coolPalettes)
        }

        if routine.tags.contains("energy") || routine.tags.contains("energize") || routine.tags.contains("morning") {
            return paletteVariant(from: Self.freshPalettes)
        }

        let groups = Set(routine.relatedMuscleGroups)
        if groups.contains("lowerBack") || groups.contains("hamstrings") || groups.contains("calves") {
            return paletteVariant(from: Self.coolPalettes)
        }

        if groups.contains("hips") || groups.contains("glutes") || groups.contains("quads") {
            return paletteVariant(from: Self.freshPalettes)
        }

        if groups.contains("neck") || groups.contains("shoulders") || groups.contains("upperBack") {
            return paletteVariant(from: Self.warmPalettes)
        }

        return paletteVariant(from: Self.neutralPalettes)
    }

    private func paletteVariant(from palettes: [[Color]]) -> [Color] {
        let seed = routine.id.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }
        return palettes[seed % palettes.count]
    }

    private var supportLine: String {
        if routine.tags.contains("desk") { return "Gentle relief for screen-heavy days" }
        if routine.tags.contains("posture") { return "Open up, stack tall, and reset your posture" }
        if routine.tags.contains("bedtime") || routine.tags.contains("relax") { return "A calm sequence to help you settle into the evening" }
        if routine.tags.contains("recovery") { return "Loosen up without overthinking your recovery" }
        let areas = routine.relatedMuscleGroups.prefix(2).compactMap { MuscleGroup(rawValue: $0)?.displayName.lowercased() }
        if areas.count == 2 { return "Focused on \(areas[0]) and \(areas[1])" }
        if let first = areas.first { return "Focused on your \(first)" }
        return "A guided routine to help you feel better fast"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Text(routine.invitingDurationLabel)
                    .font(Typography.homeMeta)
                    .foregroundStyle(Color.bfBlue)

                Text(routine.name)
                    .font(Typography.homeCardTitle)
                    .foregroundStyle(Color.bfTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(-1)
                    .lineLimit(3)

                Text(supportLine)
                    .font(Typography.homeCardSupport)
                    .foregroundStyle(Color.bfTextSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer(minLength: 0)
            }

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ForEach(Array(routine.thumbnailStretchIds.prefix(2).enumerated()), id: \.offset) { _, stretchId in
                        BodyFixThumbnailView(stretch: StretchDatabase.stretch(id: stretchId), size: 54)
                    }
                }

                HStack(spacing: 10) {
                    ForEach(Array(routine.thumbnailStretchIds.dropFirst(2).prefix(2).enumerated()), id: \.offset) { _, stretchId in
                        BodyFixThumbnailView(stretch: StretchDatabase.stretch(id: stretchId), size: 46)
                    }
                }
            }
            .frame(maxWidth: 124)
        }
        .padding(22)
        .frame(width: 302, height: 186, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: accentPalette,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.52), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 14, y: 6)
    }
}

private struct RoutineGridCard: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BodyFixThumbnailView(routine: routine, size: 52)

            VStack(alignment: .leading, spacing: 8) {
                Text(routine.name)
                    .font(Typography.homeCardTitleCompact)
                    .foregroundStyle(Color.bfTextPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(routine.durationLabel)
                    .font(Typography.homeMeta)
                    .foregroundStyle(Color.bfMint)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.025), radius: 10, y: 4)
    }
}

private struct QuickRoutineCard: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            BodyFixThumbnailView(routine: routine, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(Typography.homeCardTitleCompact)
                    .foregroundStyle(Color.bfTextPrimary)
                    .lineLimit(2)

                Text(routine.durationLabel)
                    .font(Typography.homeMeta)
                    .foregroundStyle(Color.bfMint)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 198, height: 132, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.bfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.46), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.022), radius: 8, y: 3)
    }
}

private struct SeriesCard: View {
    let series: RoutineSeries
    let completedLevel: Int

    private var levelCountLabel: String {
        let count = max(series.levelRoutineIds.count, 1)
        return count == 1 ? "1 level" : "\(count) levels"
    }

    private var representativeStretch: Stretch? {
        if let stretchId = series.imageStretchIds?.first,
           let stretch = StretchDatabase.stretch(id: stretchId) {
            return stretch
        }

        let levelRoutines = StretchDatabase.levelRoutines(for: series)
        if let stretchId = levelRoutines.first?.thumbnailStretchIds.first,
           let stretch = StretchDatabase.stretch(id: stretchId) {
            return stretch
        }

        if let group = series.relatedMuscleGroups.first.flatMap(MuscleGroup.init(rawValue:)),
           let stretch = StretchDatabase.groupedStretches(for: [group], perGroup: 1).first?.1.first {
            return stretch
        }

        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(series.name)
                        .font(Typography.homeCardTitle)
                        .foregroundStyle(Color.bfTextPrimary)
                        .lineSpacing(-1)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(levelCountLabel)
                        .font(Typography.homeCardSupport)
                        .foregroundStyle(Color.bfTextMuted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)

                SeriesProgressMeter(completedLevel: completedLevel)
            }

            ZStack {
                Circle()
                    .fill(Color.bfBlue.opacity(0.08))
                    .frame(width: 112, height: 112)
                    .blur(radius: 8)

                if let representativeStretch {
                    BodyFixThumbnailView(stretch: representativeStretch, size: 84)
                } else {
                    BodyFixThumbnailView(
                        muscleGroup: series.relatedMuscleGroups.first.flatMap(MuscleGroup.init(rawValue:)),
                        size: 84
                    )
                }
            }
            .frame(width: 100, height: 104, alignment: .top)
        }
        .padding(22)
        .frame(width: 300, height: 190, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color.bfSurfaceElevated,
                            Color.bfSurfaceMuted.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topLeading) {
                    Circle()
                        .fill(Color.bfBlue.opacity(0.06))
                        .frame(width: 136, height: 136)
                        .blur(radius: 18)
                        .offset(x: -26, y: -22)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 12, y: 4)
    }
}

private struct SeriesProgressMeter: View {
    let completedLevel: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { level in
                VStack(spacing: 6) {
                    Circle()
                        .fill(level <= completedLevel ? Color.bfMint : (level == completedLevel + 1 ? Color.bfBlue : Color.bfBorder.opacity(0.85)))
                        .frame(width: 10, height: 10)

                    Text(levelLabel(level))
                        .font(Typography.homeMeta)
                        .foregroundStyle(Color.bfTextMuted)
                }

                if level < 3 {
                    Capsule()
                        .fill(level < completedLevel ? Color.bfMint.opacity(0.7) : Color.bfBorder.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func levelLabel(_ level: Int) -> String {
        switch level {
        case 1: return "I"
        case 2: return "II"
        default: return "III"
        }
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
                .stroke(Color.bfBorder.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 5)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Typography.homeMeta)
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
                    .font(Typography.homeMeta)
                    .foregroundStyle(Color.bfTextMuted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
