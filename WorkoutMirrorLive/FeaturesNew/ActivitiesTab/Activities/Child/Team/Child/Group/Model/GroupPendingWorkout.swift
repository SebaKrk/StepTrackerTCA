//
//  GroupPendingWorkout.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 31/10/2026.
//

import SharedModels

/// A workout ready to start while the plan preview sheet is still animating out.
struct GroupPendingWorkout: Equatable {

    /// The user's copy of today's plan.
    let plan: TrainingSession

    /// HR source picked in the preview.
    let device: DeviceOption
}
