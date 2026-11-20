//
//  SubscriptionProduct.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// One subscription on sale, with every price already formatted for the storefront.
struct SubscriptionProduct: Equatable, Identifiable, Sendable {

    /// Identifier of the product in App Store Connect.
    let id: SubscriptionProductID

    /// How often the product renews.
    let period: SubscriptionPeriod

    /// Price of one period, as the App Store formats it.
    let displayPrice: String

    /// Price of one month when the period is longer than a month.
    let displayMonthlyPrice: String?

    /// Percent saved against paying monthly for the same time.
    let savingsPercent: Int?

    /// Free days the App Store grants this user before the first charge.
    let introOfferDays: Int?
}
