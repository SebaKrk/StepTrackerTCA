//
//  DictationError.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

import Foundation

/// Why dictation could not start or stopped early.
enum DictationError: Error, Equatable, Sendable {

    /// The user declined microphone access.
    case microphoneDenied

    /// No on-device speech model speaks this language.
    case unsupportedLocale

    /// The speech model is not installed yet; the system keeps downloading it.
    case modelUnavailable

    /// The microphone audio could not be converted for the speech model.
    case audioConversionFailed
}
