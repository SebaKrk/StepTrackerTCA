//
//  SharePlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture

extension SharePlanFeature {

    @CasePathable
    enum Action: ViewAction {

        /// Delivered when the QR payload has been encoded and rendered (or failed).
        case qrResultLoaded(PlanShareResult)

        /// View-originated actions — see `View` enum.
        case view(View)

        @CasePathable
        enum View {

            /// Triggered when the sheet appears — kicks off QR generation.
            case viewDidAppear
        }
    }
}
