//
//  InviteScanRow.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation
import SharedModels

/// One person on the sender's list, with the status resolved at load time.
struct InviteScanRow: Identifiable, Equatable {

    /// The person's invitation.
    let invitation: TeamInvitation

    /// Status to display.
    let state: TeamInvitationState

    var id: String { invitation.id }
}
