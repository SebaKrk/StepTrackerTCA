//
//  TrainingSession.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//

import Foundation
import HealthKit

// MARK: - Training Session (główny obiekt treningu)
public struct TrainingSession: Sendable {
    public let date: Date
    public let title: String
    public let activity: WorkoutActivityType
    public let location: WorkoutLocationType
    public let warmUp: WarmUpSession?
    public let workouts: [WorkoutSessionNew]
    public let coolDown: CoolDownSession?

    public init(date: Date, title: String, activity: WorkoutActivityType, location: WorkoutLocationType, warmUp: WarmUpSession?, workouts: [WorkoutSessionNew], coolDown: CoolDownSession?) {
        self.date = date
        self.title = title
        self.activity = activity
        self.location = location
        self.warmUp = warmUp
        self.workouts = workouts
        self.coolDown = coolDown
    }

    public static let previewTrainingSession = TrainingSession(
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
public struct WarmUpSession: Sendable {
    public let goal: SimpleWorkoutGoal
    public let time: Int?
    public let description: String?

    public init(goal: SimpleWorkoutGoal, time: Int?, description: String?) {
        self.goal = goal
        self.time = time
        self.description = description
    }
}

// MARK: - Cool Down Session
public struct CoolDownSession: Sendable {
    public let goal: SimpleWorkoutGoal
    public let time: Int?
    public let description: String?

    public init(goal: SimpleWorkoutGoal, time: Int?, description: String?) {
        self.goal = goal
        self.time = time
        self.description = description
    }
}

// MARK: - Workout Session
public struct WorkoutSessionNew: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let name: String
    public let type: ExerciseWorkoutType
    public let timeCap: Int?
    public let rounds: Int?
    public let exercises: [ExerciseSession]

    public init(name: String, type: ExerciseWorkoutType, timeCap: Int?, rounds: Int?, exercises: [ExerciseSession]) {
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
    }
}

// MARK: - Set Scheme

/// Represents a group of sets with same reps and intensity (e.g., "4×5 @ 50-60%")
public struct SetScheme: Equatable, Sendable, Codable {
    public let count: Int          // Number of sets (e.g., 4)
    public let reps: Int            // Reps per set (e.g., 5)
    public let intensity: String?   // Intensity percentage (e.g., "50-60%")

    public init(count: Int, reps: Int, intensity: String? = nil) {
        self.count = count
        self.reps = reps
        self.intensity = intensity
    }
}

// MARK: - Exercise Session

public struct ExerciseSession: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let type: ExerciseType
    public let target: ExerciseTarget?
    public let weight: WeightConfiguration?
    public let sets: [SetScheme]?   // For strength exercises with set schemes
    public let info: String?

    public init(
        type: ExerciseType,
        target: ExerciseTarget?,
        weight: WeightConfiguration?,
        sets: [SetScheme]? = nil,
        info: String?
    ) {
        self.type = type
        self.target = target
        self.weight = weight
        self.sets = sets
        self.info = info
    }
}

// MARK: - Weight Configuration
public struct WeightConfiguration: Equatable, Sendable {
    public let men: Int?
    public let women: Int?

    public init(men: Int?, women: Int?) {
        self.men = men
        self.women = women
    }
}

// MARK: - Exercise Target
public enum ExerciseTarget: Equatable, Sendable {
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
    
}
