//
//  SubscriptionClient+StoreKit.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation
import SharedModels

extension SubscriptionClient {

    /// The real App Store, through StoreKit 2.
    static let storeKit = SubscriptionClient(
        trialStrategy: {
            await StoreKitSubscriptionService.shared.trialStrategy()
        },
        products: {
            try await StoreKitSubscriptionService.shared.products()
        },
        purchase: { productID in
            try await StoreKitSubscriptionService.shared.purchase(productID)
        },
        restorePurchases: {
            try await StoreKitSubscriptionService.shared.restorePurchases()
        },
        hasActiveSubscription: {
            await StoreKitSubscriptionService.shared.hasActiveSubscription()
        },
        refreshTier: {
            let isActive = await StoreKitSubscriptionService.shared.hasActiveSubscription()
            let tier: SubscriptionTier = isActive ? .pro : .basic
            let hasChanged = tier != StoredSubscriptionTier.current
            StoredSubscriptionTier.set(tier)
            if hasChanged {
                await TierChangeEffects.tierChanged(to: tier)
            } else {
                await TierChangeEffects.tierConfirmed(tier)
            }
            return tier
        },
        overrideTier: { tier in
            StoredSubscriptionTier.set(tier)
            await TierChangeEffects.tierChanged(to: tier)
        }
    )
}
