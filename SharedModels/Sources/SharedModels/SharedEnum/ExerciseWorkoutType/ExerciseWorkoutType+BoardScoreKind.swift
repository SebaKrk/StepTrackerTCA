//
//  ExerciseWorkoutType+BoardScoreKind.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 27/10/2026.
//

import Foundation

extension ExerciseWorkoutType {

    /// The one place that decides how a block of this type is scored on a group leaderboard.
    public var boardScoreKind: BoardScoreKind {
        switch self {
        case .forTime: .time
        case .amrap: .rounds
        case .emom, .tabata: .totalReps
        case .strength, .olympicWeightlifting: .load
        case .mobility, .intervals: .none
        }
    }
}
