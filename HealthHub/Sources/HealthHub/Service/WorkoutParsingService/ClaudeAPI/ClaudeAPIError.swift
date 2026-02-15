//
//  ClaudeAPIError.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Errors that can occur during Claude API requests.
public enum ClaudeAPIError: Error, LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResponse
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API key not found. Set ANTHROPIC_API_KEY environment variable."
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .httpError(let statusCode):
            return "Claude API HTTP error: \(statusCode)"
        case .emptyResponse:
            return "Claude API returned empty response"
        case .invalidJSON:
            return "Failed to parse workout JSON from Claude response"
        }
    }
}
