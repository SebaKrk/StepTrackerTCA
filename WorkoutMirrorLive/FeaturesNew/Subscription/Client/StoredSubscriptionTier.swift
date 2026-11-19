//
//  StoredSubscriptionTier.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import SharedModels

/// The stored tier every screen reads; only `SubscriptionClient` implementations write it.
enum StoredSubscriptionTier {

    /// The tier currently stored.
    static var current: SubscriptionTier {
        @Shared(.appStorage(.subscriptionTier)) var tier: SubscriptionTier = .basic
        return tier
    }

    /// Replaces the stored tier; every screen observing it updates at once.
    static func set(_ newTier: SubscriptionTier) {
        @Shared(.appStorage(.subscriptionTier)) var tier: SubscriptionTier = .basic
        $tier.withLock { $0 = newTier }
    }
}
