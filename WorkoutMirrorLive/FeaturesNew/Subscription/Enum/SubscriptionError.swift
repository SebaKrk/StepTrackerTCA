//
//  SubscriptionError.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// Why a purchase could not be carried out.
enum SubscriptionError: Error, Equatable {

    /// The App Store does not know the product, or it is not on sale in this storefront.
    case productUnavailable

    /// The App Store returned a transaction whose signature did not verify.
    case unverifiedTransaction

    /// No foreground window to present the payment sheet in.
    case noActiveScene
}
