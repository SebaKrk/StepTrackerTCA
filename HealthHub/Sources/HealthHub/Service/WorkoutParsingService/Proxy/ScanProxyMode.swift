//
//  ScanProxyMode.swift
//  HealthHub
//
//  Created by Sebastian Ściuba on 17/11/2026.
//

import Foundation

/// Which prompt the proxy builds for a scan.
///
/// Mirrors ``WorkoutParsingBackend`` across the wire: the backend stays the app's
/// setting, this is the word the function understands.
public enum ScanProxyMode: String, Sendable {

    /// Photo only; the model reads the board itself.
    case vision

    /// Photo plus the OCR transcript as an untrusted hint.
    case visionWithHint

    /// OCR transcript only, no photo.
    case text
}
