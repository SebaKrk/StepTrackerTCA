//
//  ImportPlanFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 13/07/2026.
//

import ComposableArchitecture
import SharedModels

extension ImportPlanFeature {

    @CasePathable
    enum Action: ViewAction {

        /// View-originated actions — see `View` enum.
        case view(View)

        /// Delegate actions sent up to the parent (`PlansFeature`).
        case delegate(Delegate)

        /// Malformed-scan alert presentation.
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum View {

            /// A QR code was scanned — carries its raw string payload.
            case qrScanned(String)

            /// User confirmed adding the previewed plan to their list.
            case addTapped

            /// User dismissed the import sheet without adding.
            case cancelTapped
        }

        enum Delegate {

            /// A fresh-identity copy of the scanned plan, ready for the parent to save.
            case imported(TrainingSession)
        }

        /// No alert buttons carry actions — dismissal is enough.
        enum Alert: Equatable {}
    }
}
