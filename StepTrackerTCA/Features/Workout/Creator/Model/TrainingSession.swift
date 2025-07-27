//
//  TrainingSession.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//

import Foundation
import SwiftUI
import HealthKit

// MARK: - Training Session (główny obiekt treningu)
struct TrainingSession {
    let date: Date
    let title: String
    let activity: WorkoutActivityType
    let location: WorkoutLocationType
    let warmUp: WarmUpSession?
    let workouts: [WorkoutSessionNew]
    let coolDown: CoolDownSession?
    
    static let previewTrainingSession = TrainingSession(
        date: .now,
        title: "Clean & Jerk + Conditioning",
        activity: .crossTraining,
        location: .indoor,
        warmUp: WarmUpSession(
            goal: .timeLimit,
            time: 15,
            description: "WarmUp for Clean & Jerk - Focus on mobility and activation"
                //"WarmUp for Clean & Jerk - Focus on mobility and activation: Start with 5 min light cardio (rowing/bike), then dynamic stretching focusing on ankles, hips, and shoulders. Include: leg swings, arm circles, hip circles, overhead reaches. Practice empty barbell movements: deadlifts, front squats, overhead squats. Pay special attention to wrist mobility and thoracic spine extension. Finish with light clean pulls and front rack holds."
        ),
        workouts: [
            WorkoutSessionNew(
                name: "Weightlifting - Clean and Jerk",
                type: .forTime,
                timeCap: 20,
                rounds: 0,
                exercises: [
                    ExerciseSession(
                        type: .cleanAndJerk,
                        target: .reps(1),
                        weight: nil,
                        info: "Find one rep max in 20 min time"
                    )
                ]
            ),
            WorkoutSessionNew(
                name: "WOD 1",
                type: .forTime,
                timeCap: 12,
                rounds: 8,
                exercises: [
                    ExerciseSession(
                        type: .boxJumps,
                        target: .reps(5),
                        weight: nil,
                        info: "Box jumps"
                    ),
                    ExerciseSession(
                        type: .powerClean,
                        target: .reps(3),
                        weight: .init(men: 80, women: 50),
                        info: "Power clean @ 80/50kg"
                    )
                ]
            )
        ],
        coolDown: CoolDownSession(
            goal: .timeLimit,
            time: 10,
            description: "Post-workout recovery and mobility - Essential for heavy lifting recovery"
                //"Post-workout recovery and mobility - Essential for heavy lifting recovery: Start with 2-3 minutes walking to lower heart rate. Focus on static stretching: hip flexors, hamstrings, calves, and shoulders. Include pigeon pose for hip mobility, seated spinal twist, and doorway chest stretch. Pay attention to wrist and forearm stretches after heavy barbell work. Finish with deep breathing exercises (4-7-8 breathing pattern) to activate parasympathetic nervous system. Hydrate and consider foam rolling if available."
        )
    )
}

// MARK: - Warm Up Session
struct WarmUpSession {
    let goal: SimpleWorkoutGoal
    let time: Int?
    let description: String?
}

// MARK: - Cool Down Session
struct CoolDownSession {
    let goal: SimpleWorkoutGoal
    let time: Int?
    let description: String?
}

// MARK: - Workout Session
struct WorkoutSessionNew: Identifiable, Equatable {
    let id = UUID()
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
