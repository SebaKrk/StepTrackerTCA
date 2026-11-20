//
//  TierChangeEffects.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import HealthHub
import SharedModels

/// What has to follow the stored tier outside the screens that observe it.
///
/// The widget and the Watch only show what the iPhone sends, so they learn about a tier here.
enum TierChangeEffects {

    /// Runs after the tier changed: the lock goes out at once, a score is recalculated and sent.
    static func tierChanged(to tier: SubscriptionTier) async {
        @Dependency(\.readinessBroadcaster) var readinessBroadcaster
        @Dependency(\.trainingReadinessBackgroundManager) var backgroundManager

        if tier.opens(.readiness) {
            await backgroundManager.refreshNow()
        } else {
            await readinessBroadcaster.publishLocked()
        }
    }

    /// Runs on launch, when the tier is only confirmed: repeats the lock and leaves a score to the usual refresh.
    static func tierConfirmed(_ tier: SubscriptionTier) async {
        guard !tier.opens(.readiness) else { return }
        @Dependency(\.readinessBroadcaster) var readinessBroadcaster
        await readinessBroadcaster.publishLocked()
    }
}
