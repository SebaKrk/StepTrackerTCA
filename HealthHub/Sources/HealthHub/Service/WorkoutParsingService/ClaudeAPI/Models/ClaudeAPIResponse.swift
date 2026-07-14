//
//  ClaudeAPIResponse.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Response from Claude API.
public struct ClaudeAPIResponse: Decodable, Sendable {
    public let content: [Content]

    public struct Content: Decodable, Sendable {
        public let text: String
    }
}
