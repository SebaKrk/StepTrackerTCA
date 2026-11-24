//
//  PauseActivityVerdict.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 24/11/2026.
//

/// What the heart rate says about a paused workout.
public enum PauseActivityVerdict: Equatable, Sendable {

    /// Too early, or the heart rate is still on its way down — nothing to conclude yet.
    case undecided

    /// The heart rate is back at rest: the pause is a real one.
    case resting

    /// The heart rate stopped falling or climbed: the wearer is most likely still training.
    case stillTraining
}
