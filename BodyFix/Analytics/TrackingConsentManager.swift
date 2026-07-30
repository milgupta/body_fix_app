import Foundation

#if os(iOS) && canImport(AppTrackingTransparency)
import AppTrackingTransparency
import UIKit
#endif

#if os(iOS) && canImport(FacebookCore)
import FacebookCore
#endif

#if os(iOS)
import AppstackSDK
#endif

enum TrackingConsentManager {
    @MainActor
    static func requestIfNeeded() async {
        #if os(iOS) && canImport(AppTrackingTransparency)
        guard #available(iOS 14.0, *) else { return }

        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            syncMetaAdvertiserTrackingStatus()
            enableAppleAdsAttribution()
            return
        }

        guard UIApplication.shared.applicationState == .active else {
            syncMetaAdvertiserTrackingStatus()
            enableAppleAdsAttribution()
            return
        }

        let status = await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        syncMetaAdvertiserTrackingStatus(status: status)
        enableAppleAdsAttribution()
        #endif
    }

    static func enableAppleAdsAttribution() {
        #if os(iOS)
        if #available(iOS 15.0, *), AppstackTracker.isConfigured {
            AppstackASAAttribution.shared.enableAppleAdsAttribution()
        }
        #endif
    }

    static func syncMetaAdvertiserTrackingStatus() {
        #if os(iOS) && canImport(AppTrackingTransparency)
        guard #available(iOS 14.0, *) else { return }
        syncMetaAdvertiserTrackingStatus(status: ATTrackingManager.trackingAuthorizationStatus)
        #endif
    }

    private static func syncMetaAdvertiserTrackingStatus(status: ATTrackingManager.AuthorizationStatus) {
        #if os(iOS) && canImport(FacebookCore)
        let isAuthorized = status == .authorized

        if #available(iOS 17.0, *) {
            _ = isAuthorized
        } else {
            Settings.shared.isAdvertiserTrackingEnabled = isAuthorized
        }
        #endif
    }
}
