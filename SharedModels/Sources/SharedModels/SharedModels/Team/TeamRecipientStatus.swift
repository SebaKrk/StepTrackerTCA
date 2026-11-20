//
//  TeamRecipientStatus.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/10/2026.
//

import Foundation

/// Decision stored for one person who scanned an invite.
public enum TeamRecipientStatus: String, Codable, Sendable, Equatable {

    /// Scanned, not decided yet.
    case pending

    /// Joined the group.
    case accepted

    /// Refused the invite; scanning it again makes it pending.
    case declined
}
