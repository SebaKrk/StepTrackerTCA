//
//  WorkoutPreviewCancelID.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/10/2026.
//

import Foundation

/// Cancel identifiers of `WorkoutPreviewFeature` long-running effects.
nonisolated enum WorkoutPreviewCancelID: Hashable, Sendable {

    /// Warm-up and cool-down generation for the sections the board lacked.
    case notesGeneration
}
