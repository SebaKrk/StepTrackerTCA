//
//  WorkoutPhase.swift
//  SharedModels
//

import Foundation

/// Represents a single phase of a `TrainingSession` in execution order:
/// warm-up → WOD(s) → cool-down.
///
/// Used in `PhasePanelFeature` to guide the user through the plan during a live workout.
public enum WorkoutPhase: Identifiable, Equatable, Sendable {

    /// Optional preparatory phase before the main workouts.
    /// Contains mobility, activation, and warm-up drills.
    case warmUp(WarmUpSession)

    /// A single main workout block (e.g. "WOD 1", "Weightlifting").
    /// May have a `timeCap` driving countdown mode in the phase panel.
    case wod(WorkoutSessionNew)

    /// Optional recovery phase after the main workouts.
    /// Contains stretching and cool-down drills.
    case coolDown(CoolDownSession)

    // MARK: - Identifiable

    public var id: String {
        switch self {
        case .warmUp:      return "warmUp"
        case let .wod(w):  return w.id.uuidString
        case .coolDown:    return "coolDown"
        }
    }

    // MARK: - Display

    /// Short title shown in the panel header (e.g. "WOD 1", "Warm-Up").
    public var title: String {
        switch self {
        case .warmUp:      return "Warm-Up"
        case let .wod(w):  return w.name
        case .coolDown:    return "Cool-Down"
        }
    }

    /// Time cap in seconds for countdown mode. `nil` = stopwatch mode.
    ///
    /// Only WOD phases with an explicit `timeCap` produce a countdown.
    /// Warm-up and cool-down always run as a stopwatch.
    public var timeCap: Int? {
        guard case let .wod(w) = self, let cap = w.timeCap else { return nil }
        return cap * 60
    }

    /// Description snapshot shown below the phase title in the panel.
    public var snapshotDescription: String {
        switch self {
        case let .warmUp(w):    return w.description
        case let .wod(w):       return w.snapshotDescription
        case let .coolDown(c):  return c.description
        }
    }

}

// MARK: - TrainingSession + phases

extension TrainingSession {

    /// Ordered list of all phases extracted from this session:
    /// optional warm-up → all workouts → optional cool-down.
    public var phases: [WorkoutPhase] {
        var result: [WorkoutPhase] = []
        if let warmUp  { result.append(.warmUp(warmUp)) }
        result += workouts.map { .wod($0) }
        if let coolDown { result.append(.coolDown(coolDown)) }
        return result
    }

}
