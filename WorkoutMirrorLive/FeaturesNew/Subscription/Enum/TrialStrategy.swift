//
//  TrialStrategy.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// How a newcomer gets their free period of Pro.
enum TrialStrategy: String, Equatable, CaseIterable, Sendable {

    /// The app counts the days itself and nobody enters a card.
    case appManaged

    /// The App Store runs an introductory offer, which starts a subscription.
    case storeIntroOffer

    /// Length of the free period, in days, under either strategy.
    static let trialDays = 14

    /// App Store storefronts (ISO 3166-1 alpha-3) that get the introductory offer.
    static let introOfferStorefronts: Set<String> = ["DEU"]

    /// The strategy for a storefront; an unknown storefront gets the one without a card.
    static func strategy(forStorefront countryCode: String?) -> TrialStrategy {
        guard let countryCode, introOfferStorefronts.contains(countryCode) else {
            return .appManaged
        }
        return .storeIntroOffer
    }
}
