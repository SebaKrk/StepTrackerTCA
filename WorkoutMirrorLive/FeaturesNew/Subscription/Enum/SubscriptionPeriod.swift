//
//  SubscriptionPeriod.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// How often a subscription renews.
enum SubscriptionPeriod: Equatable, Sendable {

    /// Renews every month.
    case monthly

    /// Renews once a year.
    case yearly
}
