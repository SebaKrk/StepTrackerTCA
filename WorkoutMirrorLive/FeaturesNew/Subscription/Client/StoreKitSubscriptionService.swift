//
//  StoreKitSubscriptionService.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation
import StoreKit
import UIKit

/// Talks to the App Store through StoreKit 2; reached only through `SubscriptionClient`.
@MainActor
final class StoreKitSubscriptionService {

    /// The single instance, so fetched products are shared by every caller.
    static let shared = StoreKitSubscriptionService()

    /// Products already fetched, keyed by identifier, so a purchase does not ask twice.
    private var storeProducts: [String: Product] = [:]

    // MARK: - Reading

    /// The strategy for the storefront this Apple Account buys in.
    func trialStrategy() async -> TrialStrategy {
        let countryCode = await Storefront.current?.countryCode
        return TrialStrategy.strategy(forStorefront: countryCode)
    }

    /// The subscriptions on sale, the yearly one first.
    func products() async throws -> [SubscriptionProduct] {
        let identifiers = SubscriptionProductID.allCases.map(\.rawValue)
        let fetched = try await Product.products(for: identifiers)
        storeProducts = Dictionary(fetched.map { ($0.id, $0) }) { first, _ in first }

        let monthlyPrice = storeProducts[SubscriptionProductID.proMonthly.rawValue]?.price
        var result: [SubscriptionProduct] = []

        for product in fetched {
            guard let id = SubscriptionProductID(rawValue: product.id),
                  let subscription = product.subscription
            else { continue }

            let isYearly = subscription.subscriptionPeriod.unit == .year
            let isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer

            result.append(
                SubscriptionProduct(
                    id: id,
                    period: isYearly ? .yearly : .monthly,
                    displayPrice: product.displayPrice,
                    displayMonthlyPrice: isYearly
                        ? (product.price / 12).formatted(product.priceFormatStyle)
                        : nil,
                    savingsPercent: isYearly
                        ? Self.savingsPercent(yearly: product.price, monthly: monthlyPrice)
                        : nil,
                    introOfferDays: isEligibleForIntroOffer
                        ? Self.freeTrialDays(of: subscription.introductoryOffer)
                        : nil
                )
            )
        }

        return result.sorted { $0.period == .yearly && $1.period != .yearly }
    }

    /// Whether a subscription is active right now.
    func hasActiveSubscription() async -> Bool {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? result.payloadValue,
                  transaction.revocationDate == nil,
                  SubscriptionProductID(rawValue: transaction.productID) != nil
            else { continue }
            return true
        }
        return false
    }

    // MARK: - Buying

    /// Buys one product and reports how the attempt ended.
    func purchase(_ id: SubscriptionProductID) async throws -> PurchaseOutcome {
        if storeProducts[id.rawValue] == nil {
            _ = try await products()
        }
        guard let product = storeProducts[id.rawValue] else {
            throw SubscriptionError.productUnavailable
        }
        guard let scene = activeScene else {
            throw SubscriptionError.noActiveScene
        }

        switch try await product.purchase(confirmIn: scene) {
        case let .success(verification):
            guard case let .verified(transaction) = verification else {
                throw SubscriptionError.unverifiedTransaction
            }
            await transaction.finish()
            return .purchased
        case .userCancelled:
            return .cancelled
        case .pending:
            return .pending
        @unknown default:
            return .pending
        }
    }

    /// Asks the App Store again and says whether a subscription is active.
    func restorePurchases() async throws -> Bool {
        try await AppStore.sync()
        return await hasActiveSubscription()
    }

    // MARK: - Helpers

    /// The window the payment sheet is presented in.
    private var activeScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    /// Percent saved by the yearly price against twelve monthly ones.
    private static func savingsPercent(yearly: Decimal, monthly: Decimal?) -> Int? {
        guard let monthly, monthly > 0 else { return nil }
        let twelveMonths = monthly * 12
        guard yearly < twelveMonths else { return nil }
        let fraction = (twelveMonths - yearly) / twelveMonths
        return Int((NSDecimalNumber(decimal: fraction).doubleValue * 100).rounded())
    }

    /// Length of a free-trial offer in days; `nil` for a paid offer or none.
    private static func freeTrialDays(of offer: Product.SubscriptionOffer?) -> Int? {
        guard let offer, offer.paymentMode == .freeTrial else { return nil }
        let daysPerUnit: Int
        switch offer.period.unit {
        case .day: daysPerUnit = 1
        case .week: daysPerUnit = 7
        case .month: daysPerUnit = 30
        case .year: daysPerUnit = 365
        @unknown default: return nil
        }
        return daysPerUnit * offer.period.value * offer.periodCount
    }
}
