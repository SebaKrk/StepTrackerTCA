//
//  ScanRunMetadata.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 07/11/2026.
//

import Foundation

#if DEBUG

/// `meta.json` of a recorded scan — what it takes to tell one run from another.
public struct ScanRunMetadata: Encodable, Sendable {

    /// When the parse started.
    public let startedAt: Date

    /// How long the parse took, in milliseconds.
    public let durationMs: Int

    /// `WorkoutParsingBackend.rawValue`; without it a bad result cannot be
    /// attributed to the prompt or to OCR.
    public let backend: String

    /// Size of the JPEG the model was sent, in bytes; `nil` when the scan carried no photo.
    public let imageBytes: Int?

    /// Character count of the OCR transcript; `0` when the backend skips OCR.
    public let ocrTextLength: Int

    /// `"success"` or `"failure"`.
    public let result: String

    /// Description of the thrown error; `nil` on success.
    public let error: String?

    /// Sections the model returned; `nil` on failure.
    public let sectionCount: Int?

    /// Movements across all sections; `nil` on failure.
    public let movementCount: Int?
}

#endif
