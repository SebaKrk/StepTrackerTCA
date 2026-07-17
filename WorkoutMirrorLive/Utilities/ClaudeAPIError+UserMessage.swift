//
//  ClaudeAPIError+UserMessage.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 17/07/2026.
//

import Foundation
import HealthHub

extension ClaudeAPIError {

    /// Localized, actionable user copy for this error.
    ///
    /// `errorDescription` on `ClaudeAPIError` is developer-facing and the
    /// HealthHub package ships no string catalog — every screen presenting
    /// a Claude failure (scan parsing, warm-up/cool-down generation) must go
    /// through this mapping instead of `localizedDescription`.
    nonisolated var userMessage: String {
        switch self {
        case .missingAPIKey, .unauthorized:
            String(localized: "Invalid or missing API key. Check the key in settings.")
        case .rateLimited:
            String(localized: "Too many requests. Try again in a moment.")
        case .network:
            String(localized: "No internet connection. Check your network and try again.")
        case .serverError:
            String(localized: "Claude service is temporarily unavailable. Try again later.")
        case .invalidResponse, .httpError, .emptyResponse, .invalidJSON:
            String(localized: "Claude returned an unexpected response. Try again.")
        }
    }

    /// Maps any Claude-pipeline error to user-presentable copy: typed API
    /// errors and decoding failures get localized messages; anything else
    /// (e.g. already-localized `ScanPlanServiceError`) keeps its own text.
    nonisolated static func userMessage(for error: any Error) -> String {
        switch error {
        case let apiError as ClaudeAPIError:
            apiError.userMessage
        case is DecodingError:
            String(localized: "Claude returned an unexpected response. Try again.")
        default:
            error.localizedDescription
        }
    }
}
