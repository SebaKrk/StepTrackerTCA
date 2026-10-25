//
//  InvitationPreviewFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation

extension InvitationPreviewFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Name the group will see after joining.
        var displayName: String

        /// Current step.
        var phase: InvitationPreviewPhase = .scanning

        /// Join or decline is in flight.
        var isResponding = false
    }

}
