//
//  ScanProxyError+ScanFailure.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation
import HealthHub
import SharedModels

extension ScanProxyError {

    /// Localized, actionable user copy for this error.
    ///
    /// `errorDescription` on `ScanProxyError` is developer-facing and the
    /// HealthHub package ships no string catalog — every screen presenting a
    /// scan failure (plan parsing, warm-up/cool-down generation) goes through
    /// this mapping instead of `localizedDescription`.
    ///
    /// Our own credit running out arrives as `serviceUnavailable` and reads as a
    /// temporary outage: the state of the account behind the app is not the
    /// user's problem and not their business.
    nonisolated var scanFailure: ScanFailure {
        switch self {
        case .dailyLimitReached(let resetsAt):
            guard let resetsAt else {
                return ScanFailure(
                    title: String(localized: "Daily limit reached"),
                    message: String(localized: "You can scan two plans a day. The next scan is available tomorrow."),
                    canRetry: false
                )
            }
            let time = resetsAt.formatted(date: .omitted, time: .shortened)
            return ScanFailure(
                title: String(localized: "Daily limit reached"),
                message: String(localized: "You can scan two plans a day. The next scan is available at \(time)."),
                canRetry: false
            )

        case .serviceUnavailable:
            return ScanFailure(
                title: String(localized: "Scanning unavailable"),
                message: String(localized: "The service is not responding right now. Try again in a few minutes."),
                canRetry: true
            )

        case .rateLimited:
            return ScanFailure(
                title: String(localized: "Too many requests"),
                message: String(localized: "Wait a moment and try again."),
                canRetry: true
            )

        case .network:
            return ScanFailure(
                title: String(localized: "No connection"),
                message: String(localized: "Make sure you have a stable internet connection and try again."),
                canRetry: true
            )

        case .notSignedIn, .notConfigured:
            return ScanFailure(
                title: String(localized: "Scanning unavailable on this device"),
                message: String(localized: "Close and reopen the app, then try again."),
                canRetry: true
            )

        case .imageTooLarge, .truncated:
            return ScanFailure(
                title: String(localized: "The plan is too long"),
                message: String(localized: "Scan it in two parts — one for each half of the board."),
                canRetry: false
            )

        case .invalidImage:
            return ScanFailure(
                title: String(localized: "Could not prepare the photo"),
                message: String(localized: "Take a new photo, ideally straight at the board and in good light."),
                canRetry: false
            )

        case .invalidRequest, .invalidResponse, .refused, .unexpected:
            return ScanFailure(
                title: String(localized: "Unexpected response"),
                message: String(localized: "The scan did not go through. Try again."),
                canRetry: true
            )
        }
    }

    /// Maps any scan-pipeline error to a presentable failure: typed proxy errors
    /// get the mapping above; anything else (e.g. an already-localized
    /// `ScanPlanServiceError`) keeps its own text under a generic headline.
    nonisolated static func scanFailure(for error: any Error) -> ScanFailure {
        switch error {
        case let proxyError as ScanProxyError:
            proxyError.scanFailure
        case is DecodingError:
            ScanProxyError.invalidResponse.scanFailure
        default:
            ScanFailure(
                title: String(localized: "Scanning failed"),
                message: error.localizedDescription,
                canRetry: true
            )
        }
    }

    /// Single-sentence variant for places that present an alert rather than a
    /// full screen, such as warm-up and cool-down generation.
    nonisolated static func userMessage(for error: any Error) -> String {
        scanFailure(for: error).message
    }
}
