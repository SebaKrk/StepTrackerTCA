//
//  InviteFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import CoreGraphics
import Foundation
import SharedModels

extension InviteFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — an invite and its rendered code are ready.
        case inviteReady(TeamInvite, CGImage?)

        /// Internal — the list of people who scanned changed.
        case scansUpdated([TeamInvitation], now: Date)

        /// Internal — loading or replacing the invite failed.
        case failed

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user revokes the code and asks for a new one.
            case replaceCodeTapped

            /// Called when the user taps "Done".
            case doneTapped
        }
    }

}
