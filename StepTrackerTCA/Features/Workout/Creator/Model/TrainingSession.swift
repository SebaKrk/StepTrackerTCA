//
//  TrainingSession.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//

import Foundation
import SwiftUI

// MARK: - Training Session (główny obiekt treningu)
struct TrainingSession {
    let date: String
    let warmUp: WarmUpSession?
    let workouts: [WorkoutSessionNew]
    let coolDown: CoolDownSession?
}

// MARK: - Warm Up Session
struct WarmUpSession {
    let description: String
}

// MARK: - Cool Down Session
struct CoolDownSession {
    let description: String
}

// MARK: - Workout Session
struct WorkoutSessionNew {
    let name: String
    let type: ExerciseWorkoutType
    let timeCap: Int?
    let rounds: Int?
    let exercises: [ExerciseSession]
}

// MARK: - Exercise Session
struct ExerciseSession: Identifiable, Equatable {
    let id = UUID()
    let type: ExerciseType
    let target: ExerciseTarget?
    let weight: WeightConfiguration?
    let info: String?
}

// MARK: - Weight Configuration
struct WeightConfiguration: Equatable {
    let men: Int?
    let women: Int?
}

// MARK: - Exercise Target
enum ExerciseTarget: Equatable {
    /// Use for repetitions: '10 reps', '5 push-ups', '3 clean and jerks'
    case reps(Int)
    
    /// Use for calorie targets: '15 cal row', '50 calories bike'
    case calories(Int)
    
    /// Use for distance: '400m run', '1000 meter row', '100m sprint'
    case meters(Int)
    
    /// Use for time duration: '30 sec plank', '45 seconds work'
    case seconds(Int)
    
    /// Use for longer time durations: '2 min AMRAP', '5 minute bike'
    case minutes(Int)
    
    /// Use rarely, mainly for internal round counting
    case rounds(Int)
    
    /// Use for track/pool laps: '4 laps around track'
    case laps(Int)
    
    var displayText: Text {
        switch self {
        case .reps(let count):
            return Text("\(count)").bold() + Text(" reps").font(.caption)
        case .calories(let count):
            return Text("\(count)").bold() + Text(" cal").font(.caption)
        case .meters(let count):
            return Text("\(count)").bold() + Text(" m").font(.caption)
        case .seconds(let count):
            return Text("\(count)").bold() + Text(" sec").font(.caption)
        case .minutes(let count):
            return Text("\(count)").bold() + Text(" min").font(.caption)
        case .rounds(let count):
            return Text("\(count)").bold() + Text(" rounds").font(.caption)
        case .laps(let count):
            return Text("\(count)").bold() + Text(" laps").font(.caption)
        }
    }}
