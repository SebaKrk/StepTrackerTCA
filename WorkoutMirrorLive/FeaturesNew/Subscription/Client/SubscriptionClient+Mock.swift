//
//  SubscriptionClient+Mock.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

extension SubscriptionClient {

    /// A stand-in for the App Store: fixed products, and every purchase succeeds.
    static let mock = SubscriptionClient(
        trialStrategy: {
            .appManaged
        },
        products: {
            [
                SubscriptionProduct(
                    id: .proYearly,
                    period: .yearly,
                    displayPrice: "79,99 zł",
                    displayMonthlyPrice: "6,67 zł",
                    savingsPercent: 33,
                    introOfferDays: TrialStrategy.trialDays
                ),
                SubscriptionProduct(
                    id: .proMonthly,
                    period: .monthly,
                    displayPrice: "9,99 zł",
                    displayMonthlyPrice: nil,
                    savingsPercent: nil,
                    introOfferDays: TrialStrategy.trialDays
                )
            ]
        },
        purchase: { _ in
            try await Task.sleep(for: .milliseconds(700))
            return .purchased
        },
        restorePurchases: {
            false
        },
        hasActiveSubscription: {
            false
        }
    )
}
