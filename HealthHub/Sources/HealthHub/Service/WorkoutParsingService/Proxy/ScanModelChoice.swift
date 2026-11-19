//
//  ScanModelChoice.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// Which model a scan runs on, for comparison runs during development.
///
/// Only a debug build offers the choice and only a development deployment honours
/// it; everywhere else the server picks, so this never becomes a user-facing setting.
public enum ScanModelChoice: String, CaseIterable, Sendable, Codable {

    /// Whatever the deployment pins — the only value a release build ever sends.
    case serverDefault = ""

    /// Cheapest of the three; the open question is handwriting on a whiteboard.
    case haiku = "claude-haiku-5-5"

    /// What the scan has run on since the key moved to the server.
    case sonnet = "claude-sonnet-5-5"

    /// The ceiling, for judging how much quality the cheaper models give up.
    case opus = "claude-opus-5-5"

    /// The identifier to send, `nil` when the server should decide.
    public var requestedModel: String? {
        self == .serverDefault ? nil : rawValue
    }

    /// Short label for the picker, with where the model sits on price.
    public var displayName: String {
        switch self {
        case .serverDefault: return "Server default"
        case .haiku: return "Haiku 5.5 (cheapest)"
        case .sonnet: return "Sonnet 5.5 (mid)"
        case .opus: return "Opus 5.5 (priciest)"
        }
    }
}
