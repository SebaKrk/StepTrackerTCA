//
//  DictationPhase.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

/// Where dictation stands in a screen that offers it.
enum DictationPhase: Equatable, Sendable {

    /// No dictation; the keyboard and the send button are in charge.
    case idle

    /// Microphone permission and the speech model are being prepared.
    case preparing

    /// The microphone is live and words flow into the field.
    case recording

    /// The microphone is closed; the last words are being finalized into the field.
    case finishing
}
