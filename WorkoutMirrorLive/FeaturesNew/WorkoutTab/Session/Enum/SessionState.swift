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
    /// `TrainingManager.mirroredSessionStartedStream` emits.
    /// UI rendering lands in SP6 (Apple Fitness-style "Rozpoczynam na Apple Watch" screen).
    case waitingForWatch

    case countdown

    case session

    case summary

    var title: String {
        switch self {
        case .waitingForWatch: return "Waiting for Apple Watch"
        case .countdown: return "Countdown"
        case .session: return "Workout Session"
        case .summary: return "Workout Summary"
        }
    }

}
