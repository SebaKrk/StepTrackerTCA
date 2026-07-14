//
//  ClaudeAPIRequest.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Request to Claude API.
public struct ClaudeAPIRequest: Encodable, Sendable {
    public let model: String
    public let maxTokens: Int
    public let system: String
    public let messages: [Message]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"
        case system
        case messages
    }

    public struct Message: Encodable, Sendable {
        public let role: String
        public let content: String

        public init(role: String, content: String) {
            self.role = role
            self.content = content
        }
    }

    public init(model: String, maxTokens: Int, system: String, messages: [Message]) {
        self.model = model
        self.maxTokens = maxTokens
        self.system = system
        self.messages = messages
    }
}
