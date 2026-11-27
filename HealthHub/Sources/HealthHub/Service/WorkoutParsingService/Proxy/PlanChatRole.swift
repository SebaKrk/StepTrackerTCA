//
//  PlanChatRole.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 27/11/2026.
//

import Foundation

/// Who wrote a message in the plan chat; the raw values are the proxy's wire values.
public enum PlanChatRole: String, Codable, Sendable, Equatable {

    /// The athlete correcting the plan.
    case user

    /// The model answering.
    case assistant
}
