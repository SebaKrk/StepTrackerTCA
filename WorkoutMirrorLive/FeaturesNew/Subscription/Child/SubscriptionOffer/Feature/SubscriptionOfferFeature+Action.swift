//
//  SubscriptionOfferFeature+Action.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import ComposableArchitecture
import Foundation

extension SubscriptionOfferFeature {

    @CasePathable
    enum Action: ViewAction {

        case `internal`(Internal)

        enum Internal {

            /// The strategy and the products arrived.
            case offerLoaded(TrialStrategy, [SubscriptionProduct])

            /// The products could not be fetched.
            case offerFailed

            /// A purchase attempt ended without an error.
            case purchaseFinished(PurchaseOutcome)

            /// A purchase or a restore threw.
            case purchaseFailed

            /// A restore ended; the value says whether a subscription is active.
            case restoreFinished(Bool)
        }

        case view(View)

        enum View {

            /// The offer appeared on screen.
            case onAppear

            /// The user tapped the close button.
            case closeButtonTapped

            /// The user picked a product.
            case productTapped(SubscriptionProductID)

            /// The user tapped the purchase button.
            case purchaseButtonTapped

            /// The user chose to carry on without Pro.
            case stayOnBasicButtonTapped

            /// The user asked to restore earlier purchases.
            case restoreButtonTapped

            /// The user asked to fetch the products again.
            case retryButtonTapped
        }
    }
}
