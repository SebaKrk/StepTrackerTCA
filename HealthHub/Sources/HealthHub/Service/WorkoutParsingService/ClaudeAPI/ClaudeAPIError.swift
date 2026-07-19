//
//  ClaudeAPIError.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation

/// Errors that can occur during Claude API requests.
///
/// Typed cases (`unauthorized`, `rateLimited`, `network`…) exist so the
/// feature layer can present a localized, actionable message per cause —
/// `errorDescription` below is a developer-facing fallback, not user copy.
public enum ClaudeAPIError: Error, LocalizedError, Equatable {
    case missingAPIKey
    case unauthorized
    case rateLimited
    case serverError(statusCode: Int)
    case network
    case invalidResponse
    case httpError(statusCode: Int)
    case emptyResponse
    case invalidJSON

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Claude API key not found. Add it in the app settings."
        case .unauthorized:
            return "Claude API rejected the API key (401/403)."
        case .rateLimited:
            return "Claude API rate limit exceeded (429)."
        case .serverError(let statusCode):
            return "Claude API server error: \(statusCode)"
        case .network:
            return "Network error while contacting Claude API."
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
