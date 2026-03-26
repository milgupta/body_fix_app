import Foundation

enum StretchDatabase {
    static func loadAll() -> [Stretch] {
        guard let url = Bundle.main.url(forResource: "stretches", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stretches = try? JSONDecoder().decode([Stretch].self, from: data)
        else {
            return []
        }
        return stretches
    }

    /// Up to `perGroup` stretches per selected muscle group, in `MuscleGroup` order.
    static func stretches(for muscles: Set<MuscleGroup>, perGroup: Int = 3) -> [Stretch] {
        groupedStretches(for: muscles, perGroup: perGroup).flatMap(\.1)
    }

    /// Grouped sections for list UI.
    static func groupedStretches(for muscles: Set<MuscleGroup>, perGroup: Int = 3) -> [(MuscleGroup, [Stretch])] {
        let all = loadAll()
        var sections: [(MuscleGroup, [Stretch])] = []
        for group in MuscleGroup.allCases where muscles.contains(group) {
            let items = Array(all.filter { $0.muscleGroup == group.rawValue }.prefix(perGroup))
            if !items.isEmpty {
                sections.append((group, items))
            }
        }
        return sections
    }

    static func stretch(id: String) -> Stretch? {
        loadAll().first { $0.id == id }
    }
}
