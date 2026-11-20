//
//  InvitationPreviewFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension InvitationPreviewFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — the scanned invite was recorded; carries the clock for its status.
        case received(TeamInvitation, now: Date)

        /// Internal — the code cannot be used.
        case failed(InvitationPreviewFailure)

        /// Internal — join or decline was saved.
        case responded

        /// Messages for the parent.
        case delegate(Delegate)

        @CasePathable
        enum View {

            /// Called once the camera reads a QR code.
            case codeScanned(String)

            /// Called when the user taps "Join".
            case joinTapped

            /// Called when the user taps "Decline".
            case declineTapped

            /// Called when the user taps "Later" — the invitation stays pending.
            case laterTapped

            /// Called when the user wants to scan another code after a failure.
            case scanAgainTapped

            /// Called when the user closes the sheet.
            case closeTapped
        }

        @CasePathable
        enum Delegate {

            /// The user joined the group.
            case joined
        }
    }

}
