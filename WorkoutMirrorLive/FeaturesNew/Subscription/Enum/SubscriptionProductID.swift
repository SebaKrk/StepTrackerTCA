//
//  SubscriptionProductID.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// Product identifiers, spelled exactly as in App Store Connect.
enum SubscriptionProductID: String, Equatable, CaseIterable, Sendable {

    /// Pro, billed every month.
    case proMonthly = "mfj.pro.monthly"

    /// Pro, billed once a year.
    case proYearly = "mfj.pro.yearly"
}
