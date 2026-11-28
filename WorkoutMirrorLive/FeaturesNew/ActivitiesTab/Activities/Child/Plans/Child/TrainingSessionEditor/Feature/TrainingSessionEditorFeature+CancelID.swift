//
//  TrainingSessionEditorFeature+CancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 28/02/2026.
//

/// In-flight AI requests of the editor, cancelled when their section is switched off.
nonisolated enum TrainingSessionEditorCancelID: Hashable, Sendable {

    /// The warm-up cue request.
    case warmUpGeneration

    /// The cool-down cue request.
    case coolDownGeneration
}
