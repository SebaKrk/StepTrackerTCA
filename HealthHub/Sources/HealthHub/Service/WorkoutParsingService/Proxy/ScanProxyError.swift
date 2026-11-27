//
//  ScanProxyError.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// Why a call to the scan proxy did not return a result.
///
/// Typed cases exist so the feature layer can tell apart the three failures that
/// read completely differently to a user: the allowance is spent, the service is
/// down, or the photo itself is the problem. `errorDescription` is developer
/// facing — user copy lives in the app's `scanFailure` mapping.
public enum ScanProxyError: Error, LocalizedError, Equatable {

    /// Firebase has not been configured yet, so no endpoint can be built.
    case notConfigured

    /// No signed-in account, so the request carries no identity.
    case notSignedIn

    /// Today's free allowance is used up; `resetsAt` is when it refills.
    case dailyLimitReached(resetsAt: Date?)

    /// The proxy or the model upstream is unavailable — including our own
    /// credit running out, which the user is never told about.
    case serviceUnavailable

    /// Too many requests in a short window; retrying later works.
    case rateLimited

    /// The plan chat used up its messages; the plan is corrected by hand from here.
    case conversationLimitReached

    /// The photo was rejected as too large even after downscaling.
    case imageTooLarge

    /// The photo could not be re-encoded for upload.
    case invalidImage

    /// The request was malformed — a bug on our side, not the user's.
    case invalidRequest

    /// The model's answer was cut off before the JSON was complete.
    case truncated

    /// The model declined to answer.
    case refused

    /// The reply could not be read as a board.
    case invalidResponse

    /// The device could not reach the proxy.
    case network

    /// Anything the proxy reported that this client does not model.
    case unexpected

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Scan proxy is not configured (no Firebase project)."
        case .notSignedIn:
            return "No signed-in account for the scan proxy."
        case .dailyLimitReached:
            return "Daily scan allowance is used up."
        case .serviceUnavailable:
            return "Scan proxy is unavailable."
        case .rateLimited:
            return "Too many scan requests."
        case .conversationLimitReached:
            return "The plan chat reached its message limit."
        case .imageTooLarge:
            return "Photo is too large for one scan."
        case .invalidImage:
            return "The scanned photo could not be re-encoded for upload."
        case .invalidRequest:
            return "Scan proxy rejected the request."
        case .truncated:
            return "The model stopped before the board was complete."
        case .refused:
            return "The model refused the request."
        case .invalidResponse:
            return "Scan proxy returned an unexpected response."
        case .network:
            return "Network error while contacting the scan proxy."
        case .unexpected:
            return "Unexpected scan proxy failure."
        }
    }
}
