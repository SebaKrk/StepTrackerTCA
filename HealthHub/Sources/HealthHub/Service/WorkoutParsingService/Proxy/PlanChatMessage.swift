//
//  PlanChatMessage.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import Foundation

/// One message of the chat that corrects a scanned plan.
///
/// Only sent, never read back: the chat lives on the phone and the proxy keeps no history.
public struct PlanChatMessage: Encodable, Sendable, Equatable, Identifiable {

    /// Stable identity for the chat list; never sent to the proxy.
    public let id: UUID

    /// Who wrote the message.
    public let role: PlanChatRole

    /// The message as written.
    public let text: String

    public init(id: UUID = UUID(), role: PlanChatRole, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }

    /// The keys that travel; the id stays on the phone.
    private enum CodingKeys: String, CodingKey {

        /// Who wrote the message.
        case role

        /// The message as written.
        case text
    }
}
