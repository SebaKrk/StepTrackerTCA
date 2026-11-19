//
//  ReadinessBroadcaster.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation
import SharedModels

/// The one sender of training readiness to the Home Screen widget and the paired Watch.
///
/// Both receivers only show what they are sent, so the tier is checked here and nowhere else.
public struct ReadinessBroadcaster: Sendable {

    // MARK: - Properties

    /// Storage the widget reads its score from.
    private let widgetDataClient: WidgetDataClient

    /// Channel to the paired Watch.
    private let watchConnectivityManager: WatchConnectivityManager

    // MARK: - Lifecycle

    public init(
        widgetDataClient: WidgetDataClient,
        watchConnectivityManager: WatchConnectivityManager
    ) {
        self.widgetDataClient = widgetDataClient
        self.watchConnectivityManager = watchConnectivityManager
    }

    // MARK: - Public API

    /// Sends a score to both receivers, or the lock when the stored tier does not open readiness.
    public func publish(_ result: TrainingReadinessResult) async {
        guard SubscriptionTier.stored.opens(.readiness) else {
            await publishLocked()
            return
        }

        WidgetDataManager().setLocked(false)
        await widgetDataClient.saveReadinessResult(result)

        // A missing Watch must not fail the widget path.
        do {
            try await watchConnectivityManager.publishReadinessSnapshot(
                ReadinessSnapshot(result: result)
            )
        } catch {
            #if DEBUG
            print("❌ Failed to publish readiness to Watch: \(error.localizedDescription)")
            #endif
        }
    }

    /// Replaces whatever both receivers hold with the lock, so no earlier score stays on screen.
    public func publishLocked() async {
        WidgetDataManager().setLocked(true)
        await widgetDataClient.clear()

        do {
            try await watchConnectivityManager.publishReadinessLocked()
        } catch {
            #if DEBUG
            print("❌ Failed to publish the readiness lock to Watch: \(error.localizedDescription)")
            #endif
        }
    }
}
