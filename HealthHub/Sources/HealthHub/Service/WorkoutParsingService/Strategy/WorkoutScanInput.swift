//
//  WorkoutScanInput.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// Everything a scan can hand to a parsing backend.
///
/// Text-only backends read ``ocrText``; image-capable backends read ``imageData``
/// and may treat the OCR text as a hint. Both fields travel together so switching
/// the backend never changes what the feature layer sends.
public struct WorkoutScanInput: Sendable {

    /// JPEG data of the scanned board, `nil` when only text is available.
    public let imageData: Data?

    /// Text recognized by Vision OCR, possibly edited by the user.
    public let ocrText: String

    public init(imageData: Data?, ocrText: String) {
        self.imageData = imageData
        self.ocrText = ocrText
    }
}
