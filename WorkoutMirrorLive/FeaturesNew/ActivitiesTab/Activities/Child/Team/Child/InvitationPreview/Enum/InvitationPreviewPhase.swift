//
//  InvitationPreviewPhase.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation
import SharedModels

/// Steps of joining a group from a scanned code.
enum InvitationPreviewPhase: Equatable {

    /// Camera is looking for a code.
    case scanning

    /// The scanned invite is being read.
    case loading

    /// The invitation is shown with its status at load time.
    case preview(TeamInvitation, TeamInvitationState)

    /// The code cannot be used.
    case failure(InvitationPreviewFailure)
}
