//
//  PurchaseOutcome.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// How an attempt to buy ended, when it did not fail.
enum PurchaseOutcome: Equatable, Sendable {

    /// The subscription is active.
    case purchased

    /// The user closed the payment sheet.
    case cancelled

    /// The purchase waits for an approval outside the app, such as Ask to Buy.
    case pending
}
