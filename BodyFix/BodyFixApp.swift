import SwiftUI
import SwiftData

@main
struct BodyFixApp: App {
    var sharedModelContainer: ModelContainer = {
        makeModelContainer()
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .onAppear {
                    AnalyticsTracker.configure()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

private func makeModelContainer() -> ModelContainer {
    let schema = Schema([
        UserProfile.self,
        PersonalizedPlan.self,
        StretchSession.self,
        RoutineSeriesProgress.self,
        SavedRoutine.self,
        StretchTimingOverride.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        guard isPersistentStoreMigrationFailure(error) else {
            fatalError("Could not create ModelContainer: \(error)")
        }
        try? removeSQLiteStoreFiles(at: modelConfiguration.url)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer after store reset: \(error)")
        }
    }
}

private func isPersistentStoreMigrationFailure(_ error: Error) -> Bool {
    var current: NSError? = error as NSError
    while let e = current {
        if e.domain == NSCocoaErrorDomain, e.code == 134_110 { return true }
        current = e.userInfo[NSUnderlyingErrorKey] as? NSError
    }
    return false
}

private func removeSQLiteStoreFiles(at storeURL: URL) throws {
    let fm = FileManager.default
    let path = storeURL.path
    for suffix in ["", "-shm", "-wal"] {
        let url = URL(fileURLWithPath: path + suffix)
        if fm.fileExists(atPath: url.path) {
            try fm.removeItem(at: url)
        }
    }
}
