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
    /// Team daily plan this copy was downloaded from (`{groupId}/{day}`); `nil` for the user's own plans.
    /// Editing the plan drops it, so a changed copy no longer posts to that leaderboard.
    public let teamPlanId: String?

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String,
        activity: WorkoutActivityType,
        location: WorkoutLocationType,
        warmUp: WarmUpSession?,
        workouts: [WorkoutSessionNew],
        coolDown: CoolDownSession?,
        teamPlanId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.activity = activity
        self.location = location
        self.warmUp = warmUp
        self.workouts = workouts
        self.coolDown = coolDown
        self.teamPlanId = teamPlanId
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
        self.teamPlanId = nil
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
    /// Work/rest round timer of an `.intervals` session; nil for every other
    /// type. Optional Codable field — plans saved before it existed decode fine.
    public let interval: IntervalPlan?

    /// Board remarks that fit no field: "rest 2 min between rounds", "no clock".
    public let notes: String?

    /// EMOM cadence in seconds (60, 120 for E2MOM); display only, the session timer ignores it.
    public let everySeconds: Int?

    public init(
        name: String,
        type: ExerciseWorkoutType,
        timeCap: Int?,
        rounds: Int?,
        exercises: [ExerciseSession],
        interval: IntervalPlan? = nil,
        notes: String? = nil,
        everySeconds: Int? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.timeCap = timeCap
        self.rounds = rounds
        self.exercises = exercises
        self.interval = interval
        self.notes = notes
        self.everySeconds = everySeconds
    }

    public init(id: UUID = UUID(), draft: WorkoutSessionDraft) {
        self.id = id
        self.name = draft.name
        self.type = draft.type
        self.timeCap = draft.timeCap
        self.rounds = draft.rounds
        self.exercises = draft.exercises
        self.interval = draft.interval
        self.notes = draft.notes
        self.everySeconds = draft.everySeconds
    }
}

// MARK: - Exercise Session

public struct ExerciseSession: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let type: ExerciseType
    /// Implement stated in the scanned name; `nil` means the movement's default applies.
    public let equipment: Equipment?
    /// Explicit override made in the exercise editor; nil means legacy/automatic.
    public let equipmentSelection: ExerciseEquipmentSelection?
    public let customName: String?  // Custom name for .unknown exercises (from OCR/AI)
    public let target: ExerciseTarget?
    public let weight: WeightConfiguration?
    public let info: String?
    /// Per-set plan extracted from AI scan. Used by SetInputView to pre-fill rows.
    /// Nil when the plan has no structured set scheme (then `rounds`-based fallback is used).
    public let plannedSets: [PlannedSet]?

    /// "8/8", "10 per side": the target is per limb, so the volume doubles.
    public let perSide: Bool

    /// "max reps" / "max cal": there is no target, the athlete records what they did.
    public let isMaxEffort: Bool

    /// Buy-in / cash-out of a WOD; nil means part of every round.
    public let segment: MovementSegment?

    /// Every load option written on the board; `weight` is the rounded kg pair the session UI uses.
    public let loadTiers: [LoadTier]?

    public init(
        type: ExerciseType,
        equipment: Equipment? = nil,
        equipmentSelection: ExerciseEquipmentSelection? = nil,
        customName: String? = nil,
        target: ExerciseTarget?,
        weight: WeightConfiguration?,
        info: String?,
        plannedSets: [PlannedSet]? = nil,
        perSide: Bool = false,
        isMaxEffort: Bool = false,
        segment: MovementSegment? = nil,
        loadTiers: [LoadTier]? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.equipment = equipment
        self.equipmentSelection = equipmentSelection
        self.customName = customName
        self.target = target
        self.weight = weight
        self.info = info
        self.plannedSets = plannedSets
        self.perSide = perSide
        self.isMaxEffort = isMaxEffort
        self.segment = segment
        self.loadTiers = loadTiers
    }

    public init(id: UUID = UUID(), draft: ExerciseSessionDraft) {
        self.id = id
        self.type = draft.type
        self.equipment = draft.equipment
        self.equipmentSelection = draft.equipmentSelection
        self.customName = draft.type == .unknown ? draft.customName : nil
        self.target = draft.target
        self.weight = draft.weight
        self.info = draft.info.isEmpty ? nil : draft.info
        self.plannedSets = draft.plannedSets
        self.perSide = draft.perSide
        self.isMaxEffort = draft.isMaxEffort
        self.segment = draft.segment
        self.loadTiers = draft.loadTiers
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, equipment, equipmentSelection, customName, target, weight, info, plannedSets
        case perSide, isMaxEffort, segment, loadTiers
    }

    // Plans saved before the flags existed lack the keys — read them as false / absent.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(ExerciseType.self, forKey: .type)
        self.equipment = try container.decodeIfPresent(Equipment.self, forKey: .equipment)
        self.equipmentSelection = try container.decodeIfPresent(ExerciseEquipmentSelection.self, forKey: .equipmentSelection)
        self.customName = try container.decodeIfPresent(String.self, forKey: .customName)
        self.target = try container.decodeIfPresent(ExerciseTarget.self, forKey: .target)
        self.weight = try container.decodeIfPresent(WeightConfiguration.self, forKey: .weight)
        self.info = try container.decodeIfPresent(String.self, forKey: .info)
        self.plannedSets = try container.decodeIfPresent([PlannedSet].self, forKey: .plannedSets)
        self.perSide = try container.decodeIfPresent(Bool.self, forKey: .perSide) ?? false
        self.isMaxEffort = try container.decodeIfPresent(Bool.self, forKey: .isMaxEffort) ?? false
        self.segment = try container.decodeIfPresent(MovementSegment.self, forKey: .segment)
        self.loadTiers = try container.decodeIfPresent([LoadTier].self, forKey: .loadTiers)
    }

    /// Display name - uses customName for .unknown exercises, otherwise the catalog
    /// name with the implement spelled out when it is not the movement's usual one.
    public var displayName: String {
        if type == .unknown, let custom = customName {
            return custom.capitalized  // Capitalize first letter
        }
        return type.displayName(with: effectiveEquipment)
    }

    /// Equipment used for display and result-entry behavior.
    public var effectiveEquipment: Equipment? {
        switch equipmentSelection {
        case .some(.automatic), nil:
            return equipment ?? type.defaultEquipment
        case .some(.none):
            return nil
        case let .some(.equipment(value)):
            return value
        }
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
