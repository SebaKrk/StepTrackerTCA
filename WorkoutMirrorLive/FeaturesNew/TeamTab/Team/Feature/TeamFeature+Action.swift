//
//  TeamFeature+Action.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

extension TeamFeature {

    @CasePathable
    enum Action: ViewAction {

        case view(View)

        /// Internal — signed in; carries the account id and the name shown to others.
        case signedIn(uid: String, displayName: String)

        /// Internal — the live list of groups changed.
        case groupsUpdated([TeamGroup])

        /// Internal — sign-in or the groups listener failed.
        case groupsFailed

        // MARK: - Destination

        /// Handles navigation destinations within this feature.
        case destination(PresentationAction<Destination.Action>)

        @CasePathable
        enum View {

            /// Called when the view appears.
            case viewDidAppear

            /// Called when the user switches between Private and Public.
            case segmentChanged(TeamSegment)

            /// Called when the user taps "Try again" after a failure.
            case retryTapped

            /// Called when the user taps "+" or "Create Group".
            case createGroupTapped
        }
    }

}
