//
//  DictationEvent.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 28/11/2026.
//

/// What a dictation session reports while it runs.
enum DictationEvent: Equatable, Sendable {

    /// The microphone is open and listening.
    case listening

    /// Everything said so far, already merged; it replaces the previous transcript.
    case transcript(String)
}
