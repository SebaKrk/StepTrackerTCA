//
//  SubscriptionOfferFeature+State.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import SharedModels
import SwiftUI

extension SubscriptionOfferFeature {

    @ObservableState
    struct State: Equatable {

        /// The tier the whole app reads; a purchase raises it to Pro.
        @Shared(.appStorage(.subscriptionTier))
        var subscriptionTier: SubscriptionTier = .basic

        /// A strategy forced by whoever opened the offer; `nil` asks the storefront.
        var strategyOverride: TrialStrategy?

        /// The strategy the offer is worded for.
        var strategy: TrialStrategy = .appManaged

        /// The subscriptions on sale, the yearly one first.
        var products: [SubscriptionProduct] = []

        /// The product the purchase button buys.
        var selectedProductID: SubscriptionProductID = .proYearly

        /// Workouts recorded during the free period.
        var recordedWorkouts = 0

        /// Plans saved during the free period.
        var savedPlans = 0

        /// Personal records set during the free period.
        var personalRecords = 0

        /// Whether the products are still on their way.
        var isLoading = true

        /// Whether the products could not be fetched.
        var hasLoadFailed = false

        /// Whether a purchase or a restore is in flight.
        var isPurchasing = false

        /// Whether the last purchase attempt failed.
        var hasPurchaseFailed = false

        // MARK: - Computed Properties

        /// The product the purchase button buys, once the products are in.
        var selectedProduct: SubscriptionProduct? {
            products.first { $0.id == selectedProductID }
        }

        /// Whether there is anything to show in the summary of the free period.
        var hasRecordedAnything: Bool {
            recordedWorkouts + savedPlans + personalRecords > 0
        }

        /// Free days before the first charge; set only when the App Store runs the trial.
        var freeTrialDays: Int? {
            guard strategy == .storeIntroOffer else { return nil }
            return selectedProduct?.introOfferDays
        }
    }
}
