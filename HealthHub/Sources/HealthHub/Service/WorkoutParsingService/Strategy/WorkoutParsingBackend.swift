//
//  WorkoutParsingBackend.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Selects which backend turns a scan into a ``ScannedBoard``.
///
/// Persisted as an app setting so the path can be switched at runtime.
/// Adding a backend = add a case here + a ``WorkoutParsingStrategy`` implementation
/// + extend the switch in ``WorkoutParsingStrategyFactory``.
public enum WorkoutParsingBackend: String, CaseIterable, Sendable, Codable {

    /// Photo → Vision OCR → text → Claude. The original pipeline.
    case claudeText

    /// Photo only → Claude. The default: on the handwritten board the OCR hint
    /// added tokens and one misread without fixing anything.
    case claudeVision

    /// Photo + OCR transcript as an untrusted hint → Claude. Kept for comparison runs.
    case claudeVisionWithOCRHint

    /// Whether Vision OCR must run before this backend can parse.
    public var needsOCRText: Bool {
        switch self {
        case .claudeText, .claudeVisionWithOCRHint: return true
        case .claudeVision: return false
        }
    }

    /// Whether the photo itself is sent; text-only backends never upload one.
    public var needsPhoto: Bool {
        switch self {
        case .claudeVision, .claudeVisionWithOCRHint: return true
        case .claudeText: return false
        }
    }

    /// The word the proxy understands for this backend's prompt.
    public var proxyMode: ScanProxyMode {
        switch self {
        case .claudeText: return .text
        case .claudeVision: return .vision
        case .claudeVisionWithOCRHint: return .visionWithHint
        }
    }

    /// Whether the user reviews the OCR text before parsing; only when text is the source of truth.
    public var showsTextStep: Bool {
        self == .claudeText
    }
}
