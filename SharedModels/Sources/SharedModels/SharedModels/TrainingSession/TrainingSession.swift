//
//  TrainingSession.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 07/07/2025.
//

import Foundation
import HealthKit

// MARK: - Training Session (główny obiekt treningu)
public struct TrainingSession: Identifiable, Equatable, Codable, Sendable {
    
    public let id: UUID
    public let date: Date
    public let title: String
    public let activity: WorkoutActivityType
    public let location: WorkoutLocationType
    public let warmUp: WarmUpSession?
    public let workouts: [WorkoutSessionNew]
    public let coolDown: CoolDownSession?

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        activity: WorkoutActivityType,
        location: WorkoutLocationType,
        warmUp: WarmUpSession?,
        workouts: [WorkoutSessionNew],
        coolDown: CoolDownSession?
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.activity = activity
        self.location = location
        self.warmUp = warmUp
        self.workouts = workouts
        self.coolDown = coolDown
    }

    public init(id: UUID = UUID(), draft: TrainingSessionDraft) {
        self.id = id
        self.date = draft.date
        self.title = draft.title
        self.activity = draft.activity
        self.location = draft.location
        self.warmUp = draft.warmUp
        self.workouts = draft.workouts
        self.coolDown = draft.coolDown
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
                rounds: nil,
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
                        info: nil
                    ),
                    ExerciseSession(
                        type: .powerClean,
                        target: .reps(3),
                        weight: .init(men: 80, women: 50),
                        info: nil
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
public struct WarmUpSession: Equatable, Codable, Sendable {
    public var goal: SimpleWorkoutGoal
    public var time: Int?
    public var description: String

    public init(goal: SimpleWorkoutGoal, time: Int?, description: String = "") {
        self.goal = goal
        self.time = time
        self.description = description
    }
}

// MARK: - Cool Down Session
public struct CoolDownSession: Equatable, Codable, Sendable {
    public var goal: SimpleWorkoutGoal
    public var time: Int?
    public var description: String

    public init(goal: SimpleWorkoutGoal, time: Int?, description: String = "") {
        self.goal = goal
        self.time = time
        self.description = description
    }
}

// MARK: - Workout Session
public struct WorkoutSessionNew: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let type: ExerciseWorkoutType
    public let timeCap: Int?
    public let rounds: Int?
    public let exercises: [ExerciseSession]

    public init(name: String, type: ExerciseWorkoutType, timeCap: Int?, rounds: Int?, exercises: [ExerciseSession]) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
    }

    public init(id: UUID = UUID(), draft: WorkoutSessionDraft) {
        self.id = id
        self.name = draft.name
        self.type = draft.type
        self.timeCap = draft.timeCap
        self.rounds = draft.rounds
        self.exercises = draft.exercises
    }
}

// MARK: - Exercise Session

public struct ExerciseSession: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let type: ExerciseType
    public let customName: String?  // Custom name for .unknown exercises (from OCR/AI)
    public let target: ExerciseTarget?
    public let weight: WeightConfiguration?
    public let info: String?

    public init(
        type: ExerciseType,
        customName: String? = nil,
        target: ExerciseTarget?,
        weight: WeightConfiguration?,
        info: String?
    ) {
        self.id = UUID()
        self.type = type
        self.customName = customName
        self.target = target
        self.weight = weight
        self.info = info
    }

    public init(id: UUID = UUID(), draft: ExerciseSessionDraft) {
        self.id = id
        self.type = draft.type
        self.customName = draft.type == .unknown ? draft.customName : nil
        self.target = draft.target
        self.weight = draft.weight
        self.info = draft.info.isEmpty ? nil : draft.info
    }

    /// Display name - uses customName for .unknown exercises, otherwise type.displayName
    public var displayName: String {
        if type == .unknown, let custom = customName {
            return custom.capitalized  // Capitalize first letter
        }
        return type.displayName
    }
}

// MARK: - Weight Configuration
public struct WeightConfiguration: Equatable, Codable, Sendable {
    public let men: Int?
    public let women: Int?

    public init(men: Int?, women: Int?) {
        self.men = men
        self.women = women
    }
}

// MARK: - Exercise Target
public enum ExerciseTarget: Equatable, Codable, Sendable {
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

    /// Compact string for snapshot display, e.g. "5x", "400m", "15 cal".
    public var compactString: String {
        switch self {
        case .reps(let n):     return "\(n)x"
        case .calories(let n): return "\(n) cal"
        case .meters(let n):   return "\(n)m"
        case .seconds(let n):  return "\(n)s"
        case .minutes(let n):  return "\(n) min"
        case .rounds(let n):   return "\(n) rounds"
        case .laps(let n):     return "\(n) laps"
        }
    }
}

// MARK: - Snapshot

extension WeightConfiguration {
    /// Compact weight string, e.g. "43/30kg", "80kg".
    public var compactString: String {
        switch (men, women) {
        case let (m?, w?): return "\(m)/\(w)kg"
        case let (m?, nil): return "\(m)kg"
        case let (nil, w?): return "\(w)kg"
        case (nil, nil): return ""
        }
    }
}

extension ExerciseSession {
    /// Snapshot line(s) for an exercise, e.g. "5x Thruster 43/30kg" or "1x Clean & Jerk\nInfo: find 1RM".
    public var snapshotLine: String {
        var parts: [String] = []
        if let target { parts.append(target.compactString) }
        parts.append(displayName)
        if let weight, !weight.compactString.isEmpty { parts.append(weight.compactString) }
        var result = parts.joined(separator: " ")
        if let info { result += "\nInfo: \(info)" }
        return result
    }
}

extension WorkoutSessionNew {
    /// Compact multi-line snapshot of the workout.
    /// Used as `description` in `WorkoutSessionResult` — immutable history.
    public var snapshotDescription: String {
        var lines: [String] = []

        var header: [String] = []
        if let rounds { header.append("\(rounds) rounds") }
        if let timeCap { header.append("\(timeCap) min cap") }
        if !header.isEmpty { lines.append(header.joined(separator: ", ")) }

        for exercise in exercises {
            lines.append(exercise.snapshotLine)
        }

        return lines.joined(separator: "\n")
    }
}
