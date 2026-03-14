import Foundation

struct StretchDatabase {
    static func loadAll() -> [Stretch] {
        guard let url = Bundle.main.url(forResource: "stretches", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stretches = try? JSONDecoder().decode([Stretch].self, from: data)
        else {
            return []
        }
        return stretches
    }

    static func stretches(for region: BodyRegion, difficulty: String? = nil) -> [Stretch] {
        let all = loadAll()
        let filtered = all.filter { $0.targetRegions.contains(region.rawValue) }

        if let difficulty {
            return filtered.filter { $0.difficulty == difficulty }
        }
        return filtered
    }

    static func stretches(forPainArea area: OnboardingPainArea) -> [Stretch] {
        let all = loadAll()
        return all.filter { $0.targetRegions.contains(area.rawValue) }
    }
}
