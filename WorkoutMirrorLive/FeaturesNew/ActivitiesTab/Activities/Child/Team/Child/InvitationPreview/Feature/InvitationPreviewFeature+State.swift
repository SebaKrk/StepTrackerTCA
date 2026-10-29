//
//  InvitationPreviewFeature+State.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import ComposableArchitecture
import Foundation
import SwiftUI

extension InvitationPreviewFeature {

    @ObservableState
    struct State: Equatable {

        // MARK: - Properties

        /// Name the group will see after joining.
        var displayName: String

        /// Accent of the Team tab — background gradient and prominent controls.
        var color: Color

        /// Current step.
        var phase: InvitationPreviewPhase = .scanning

        /// Join or decline is in flight.
        var isResponding = false
    }

}
