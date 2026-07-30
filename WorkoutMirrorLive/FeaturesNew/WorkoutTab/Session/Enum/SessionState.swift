//
//  SessionState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import Foundation

enum SessionState {

    /// Watch-primary mode pre-countdown — iPhone is waiting for Apple Watch to start
    /// the mirrored HKWorkoutSession. Transitions to `.countdown` when
    /// `TrainingManager.mirroredSessionStartedStream` emits. The "Rozpoczynam na Apple
    /// Watch" screen is rendered by `CountDownView` in its waiting phase.
    case waitingForWatch

    case countdown

    case session

    case summary

    /// Watch-primary post-end state (IOS-00098-E). The Watch — as the primary session
    /// owner — shows the immediate summary; iPhone only confirms the workout ended and
    /// points the user to History for results entry. Replaces the old `.summary` flow
    /// with its 10s `.workoutSaved` timeout + 40-attempt HealthKit poll.
    case finishedOnWatch

    var title: String {
        switch self {
        case .waitingForWatch: return "Waiting for Apple Watch"
        case .countdown: return "Countdown"
        case .session: return "Workout Session"
        case .summary: return "Workout Summary"
        case .finishedOnWatch: return "Workout Ended"
        }
    }

}
