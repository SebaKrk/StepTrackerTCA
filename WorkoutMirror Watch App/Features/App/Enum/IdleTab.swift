//
//  IdleTab.swift
//  WorkoutMirror Watch App
//
//  Created by Sebastian Sciuba on 27/09/2026.
//

/// Tabs of the idle screen, shown while no workout is active.
enum IdleTab: Hashable {

    /// Daily training readiness pushed from the paired iPhone.
    case readiness

    /// Placeholder shown while waiting for a workout to start on iPhone.
    case waitingForWorkout
}
