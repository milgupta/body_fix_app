import SwiftUI
import SwiftData

#if os(iOS) && canImport(FacebookCore)
import FacebookCore
import UIKit
#endif

@main
struct BodyFixApp: App {
    @Environment(\.scenePhase) private var scenePhase

    #if os(iOS) && canImport(FacebookCore)
    @UIApplicationDelegateAdaptor(BodyFixAppDelegate.self) private var appDelegate
    #endif

    var sharedModelContainer: ModelContainer = {
        makeModelContainer()
    }()

    init() {
        AppstackTracker.configure()
        AnalyticsTracker.configure()
        PaywallManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            TrackingConsentManager.syncMetaAdvertiserTrackingStatus()
            TrackingConsentManager.enableAppleAdsAttribution()
            AnalyticsTracker.capture("bodyfix_app_launch_test")
            #if os(iOS) && canImport(FacebookCore)
            AppEvents.shared.activateApp()
            AppEvents.shared.flush()
            #endif
        }
    }
}

#if os(iOS) && canImport(FacebookCore)
final class BodyFixAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[.sourceApplication] as? String,
            annotation: options[.annotation]
        )
    }
}
#endif

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
