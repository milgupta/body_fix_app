import SwiftUI
import SwiftData
import OSLog

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

    private let sharedModelContainer: ModelContainer? = {
        makeModelContainer()
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let sharedModelContainer {
                    ContentView()
                        .modelContainer(sharedModelContainer)
                } else {
                    StartupRecoveryView()
                }
            }
            .preferredColorScheme(.light)
            .task {
                // Keep optional analytics and paywall SDK work out of the
                // pre-scene launch path so the first frame can render first.
                await Task.yield()
                StartupServices.configureIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            StartupServices.configureIfNeeded()
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

private enum StartupServices {
    private static var isConfigured = false

    static func configureIfNeeded() {
        guard !isConfigured else { return }
        isConfigured = true
        AppstackTracker.configure()
        AnalyticsTracker.configure()
        PaywallManager.shared.configure()
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

private let persistenceLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "royalapps.BodyFix",
    category: "Persistence"
)

private func makeModelContainer() -> ModelContainer? {
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
        persistenceLogger.fault(
            "Unable to open the persistent store. Attempting recovery. Error: \(error.localizedDescription, privacy: .public)"
        )

        do {
            try quarantineSQLiteStoreFiles(at: modelConfiguration.url)
        } catch {
            persistenceLogger.error(
                "Could not quarantine the persistent store: \(error.localizedDescription, privacy: .public)"
            )
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            persistenceLogger.fault(
                "Persistent-store recovery failed. Falling back to an in-memory store. Error: \(error.localizedDescription, privacy: .public)"
            )
        }

        let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [memoryConfiguration])
        } catch {
            persistenceLogger.fault(
                "Unable to create the in-memory fallback store: \(error.localizedDescription, privacy: .public)"
            )
            return nil
        }
    }
}

private func quarantineSQLiteStoreFiles(at storeURL: URL) throws {
    let fm = FileManager.default
    let path = storeURL.path
    let quarantineID = UUID().uuidString

    for suffix in ["", "-shm", "-wal"] {
        let sourceURL = URL(fileURLWithPath: path + suffix)
        guard fm.fileExists(atPath: sourceURL.path) else { continue }

        let destinationURL = URL(
            fileURLWithPath: path + ".recovery-\(quarantineID)" + suffix
        )
        try fm.moveItem(at: sourceURL, to: destinationURL)
    }
}

private struct StartupRecoveryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color.bfBlue)

            Text("Body Fix needs to restart")
                .font(.title2.weight(.bold))

            Text("Your data is still on this device. Close Body Fix, make sure you have free storage, then open it again.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bfBackground)
    }
}
