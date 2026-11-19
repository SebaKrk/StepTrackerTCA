//
//  SubscriptionClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import Foundation

/// The one boundary every purchase goes through, so no screen talks to the App Store itself.
@DependencyClient
struct SubscriptionClient: Sendable {

    /// Which free period the current storefront gets.
    var trialStrategy: @Sendable () async -> TrialStrategy = { .appManaged }

    /// The subscriptions on sale, the yearly one first.
    var products: @Sendable () async throws -> [SubscriptionProduct]

    /// Buys one product and reports how the attempt ended.
    var purchase: @Sendable (SubscriptionProductID) async throws -> PurchaseOutcome

    /// Asks the App Store again and says whether a subscription is active.
    var restorePurchases: @Sendable () async throws -> Bool

    /// Whether a subscription is active right now.
    var hasActiveSubscription: @Sendable () async -> Bool = { false }
}

extension DependencyValues {
    var subscriptionClient: SubscriptionClient {
        get { self[SubscriptionClient.self] }
        set { self[SubscriptionClient.self] = newValue }
    }
}

extension SubscriptionClient: DependencyKey {

    // MARK: - Live Value

    // Becomes `.storeKit` the day the products exist in App Store Connect.
    static let liveValue: SubscriptionClient = .mock

    // MARK: - Preview Value

    static var previewValue: SubscriptionClient { .mock }

    // MARK: - Test Value

    static var testValue: SubscriptionClient { SubscriptionClient() }
}
