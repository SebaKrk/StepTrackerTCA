//
//  TeamInvitationState.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Status of an invitation as shown to people — combines the stored decision with the invite's validity.
public enum TeamInvitationState: Equatable, Sendable {

    /// Waiting for a decision.
    case pending

    /// The person joined.
    case accepted

    /// The person refused.
    case declined

    /// The invite ran out before a decision.
    case expired

    /// The invite was withdrawn before a decision.
    case revoked
}
