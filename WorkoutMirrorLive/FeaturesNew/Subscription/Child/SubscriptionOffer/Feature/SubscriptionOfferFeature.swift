//
//  SubscriptionOfferFeature.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels
import SwiftUI

/// The offer of Pro: shown when the free period is over, or to start one run by the App Store.
@Reducer
struct SubscriptionOfferFeature {

    // MARK: - Dependency

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.subscriptionClient) var subscriptionClient

    // MARK: - Reducer

    var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {

                // MARK: - Internal Actions

            case let .internal(.offerLoaded(strategy, products)):
                state.strategy = strategy
                state.products = products
                state.isLoading = false
                if state.selectedProduct == nil, let first = products.first {
                    state.selectedProductID = first.id
                }
                return .none

            case .internal(.offerFailed):
                state.isLoading = false
                state.hasLoadFailed = true
                return .none

            case let .internal(.purchaseFinished(outcome)):
                state.isPurchasing = false
                guard outcome == .purchased else { return .none }
                return refreshTierAndClose()

            case .internal(.purchaseFailed):
                state.isPurchasing = false
                state.hasPurchaseFailed = true
                return .none

            case let .internal(.restoreFinished(isActive)):
                state.isPurchasing = false
                guard isActive else { return .none }
                return refreshTierAndClose()

                // MARK: - View Actions

            case .view(.onAppear), .view(.retryButtonTapped):
                state.isLoading = true
                state.hasLoadFailed = false
                return .run { [override = state.strategyOverride] send in
                    do {
                        var strategy = await subscriptionClient.trialStrategy()
                        if let override {
                            strategy = override
                        }
                        let products = try await subscriptionClient.products()
                        await send(.internal(.offerLoaded(strategy, products)), animation: .default)
                    } catch {
                        await send(.internal(.offerFailed), animation: .default)
                    }
                }

            case .view(.closeButtonTapped), .view(.stayOnBasicButtonTapped):
                return .run { _ in
                    await dismiss()
                }

            case let .view(.productTapped(id)):
                state.selectedProductID = id
                return .none

            case .view(.purchaseButtonTapped):
                guard !state.isPurchasing else { return .none }
                state.isPurchasing = true
                state.hasPurchaseFailed = false
                return .run { [id = state.selectedProductID] send in
                    do {
                        let outcome = try await subscriptionClient.purchase(id)
                        await send(.internal(.purchaseFinished(outcome)), animation: .default)
                    } catch {
                        await send(.internal(.purchaseFailed), animation: .default)
                    }
                }

            case .view(.restoreButtonTapped):
                guard !state.isPurchasing else { return .none }
                state.isPurchasing = true
                state.hasPurchaseFailed = false
                return .run { send in
                    do {
                        let isActive = try await subscriptionClient.restorePurchases()
                        await send(.internal(.restoreFinished(isActive)), animation: .default)
                    } catch {
                        await send(.internal(.purchaseFailed), animation: .default)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Lets the client store the tier the purchase earned, then closes the offer.
    private func refreshTierAndClose() -> Effect<Action> {
        .run { _ in
            _ = await subscriptionClient.refreshTier()
            await dismiss()
        }
    }
}
