//
//  SubscriptionClient+StoreKit.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

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
        }
    )
}
