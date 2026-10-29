//
//  ScannedBoard+Mapper.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

extension ScannedBoard {

    /// Converts the scanned board into a plan the editor, session and Summary understand.
    ///
    /// The board carries no date, so the session is dated to the scan moment —
    /// the user adjusts it in the editor when the plan is for another day.
    public func toTrainingSession(scanDate: Date = Date()) -> TrainingSession {
        let warmUp = sections.first { $0.kind == .warmup }.map { section in
            WarmUpSession(goal: .timeLimit, time: section.writtenMinutes, description: section.boardText)
        }
        let coolDown = sections.first { $0.kind == .cooldown }.map { section in
            CoolDownSession(goal: .timeLimit, time: section.writtenMinutes, description: section.boardText)
        }
        var workouts = workoutSections.map { $0.toWorkoutSessionNew() }
        if classTimeCapMin > 0, let first = workouts.first {
            // Informational only: a class budget is never a block cap.
            workouts[0] = first.appendingNote("Class budget \(Self.minutes(classTimeCapMin)) min")
        }
        return TrainingSession(
            date: scanDate,
            title: title.isEmpty ? "Workout" : title,
            activity: WorkoutActivityType(rawValue: activity) ?? .crossTraining,
            location: .indoor,
            warmUp: warmUp,
            workouts: workouts,
            coolDown: coolDown
        )
    }

    fileprivate static func minutes(_ value: Double) -> Int {
        Int(value.rounded(.up))
    }
}

// MARK: - Section

extension ScannedSection {

    fileprivate var writtenMinutes: Int? {
        writtenDurationMin > 0 ? ScannedBoard.minutes(writtenDurationMin) : nil
    }

    fileprivate var boardText: String {
        text.isEmpty ? name : text
    }

    fileprivate func toWorkoutSessionNew() -> WorkoutSessionNew {
        let exercises = movements.map { $0.toExerciseSession(repScheme: repScheme) }
        let type = workoutType(firstExercise: exercises.first)
        let cap = timeCapMin > 0
            ? ScannedBoard.minutes(timeCapMin)
            : (type.isTimerRequired ? type.defaultTimeCapMinutes : nil)
        let interval: IntervalPlan? = (type == .intervals && workSec > 0)
            ? IntervalPlan(workSeconds: workSec, restSeconds: restSec, rounds: max(roundCount, 1))
            : nil
        return WorkoutSessionNew(
            name: displayName,
            type: type,
            timeCap: cap,
            rounds: rounds(for: type),
            exercises: exercises,
            interval: interval,
            plannedMinutes: writtenMinutes ?? estimatedMinutes(cap: cap),
            notes: combinedNotes,
            everySeconds: type == .emom ? (everySec > 0 ? everySec : 60) : nil
        )
    }

    /// Format decides the block type; kind only breaks the tie for untimed work.
    private func workoutType(firstExercise: ExerciseSession?) -> ExerciseWorkoutType {
        if kind == .mobility { return .mobility }
        switch format {
        case .forTime: return .forTime
        case .amrap, .maxEffort: return .amrap
        case .emom: return .emom
        case .tabata: return .tabata
        case .intervals: return .intervals
        case .roundsUntimed: return .strength
        case .none:
            if kind == .conditioning { return .amrap }
            return firstExercise?.type.category == .olympicLifting ? .olympicWeightlifting : .strength
        }
    }

    private func rounds(for type: ExerciseWorkoutType) -> Int? {
        switch type {
        case .forTime, .tabata, .strength, .olympicWeightlifting:
            if roundCount > 0 { return roundCount }
            return (type == .forTime && !repScheme.isEmpty) ? repScheme.count : nil
        case .amrap, .emom, .mobility, .intervals:
            return nil
        }
    }

    private func estimatedMinutes(cap: Int?) -> Int? {
        if let cap { return cap + 3 }
        switch kind {
        case .mobility: return 10
        case .strength, .skill, .accessory: return 12
        case .conditioning, .warmup, .cooldown: return nil
        }
    }

    private var displayName: String {
        if !name.isEmpty { return name }
        if !label.isEmpty { return label }
        return kind.rawValue.capitalized
    }

    private var combinedNotes: String? {
        var parts: [String] = []
        if !notes.isEmpty { parts.append(notes) }
        if restBetweenRoundsSec > 0 { parts.append("Rest \(restBetweenRoundsSec) s between rounds") }
        if !uncertain.isEmpty { parts.append("Check: " + uncertain.joined(separator: ", ")) }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
}

// MARK: - Movement

extension ScannedMovement {

    fileprivate func toExerciseSession(repScheme: [Int]) -> ExerciseSession {
        let resolved = ExerciseType.resolve(rawName: name.isEmpty ? rawName : name)
        #if DEBUG
        if resolved.type == .unknown {
            print("⚠️ [BoardMapper] Unknown exercise '\(name)' (raw '\(rawName)') → using '.unknown'")
        }
        #endif
        let plannedSets = self.plannedSets(repScheme: repScheme)
        return ExerciseSession(
            type: resolved.type,
            equipment: resolved.equipment,
            customName: resolved.type == .unknown ? (rawName.isEmpty ? name : rawName) : nil,
            target: plannedSets == nil ? target : nil,
            weight: weightConfiguration,
            info: info,
            plannedSets: plannedSets,
            perSide: perSide,
            isMaxEffort: maxEffort,
            segment: segment == .round ? nil : segment,
            loadTiers: loads.isEmpty ? nil : loads.map { $0.loadTier }
        )
    }

    private var target: ExerciseTarget? {
        guard !maxEffort, targetValue > 0 else { return nil }
        let value = Int(targetValue.rounded())
        switch targetUnit {
        case .reps: return .reps(value)
        case .seconds: return .seconds(value)
        case .minutes: return .minutes(value)
        case .meters: return .meters(value)
        case .km: return .meters(Int((targetValue * 1000).rounded()))
        case .calories: return .calories(value)
        case .laps: return .laps(value)
        }
    }

    /// A written set scheme wins; a section ladder applies to every movement done each round.
    private func plannedSets(repScheme: [Int]) -> [PlannedSet]? {
        if !sets.isEmpty {
            return sets.map { set in
                PlannedSet(
                    reps: Int(set.value.rounded()),
                    suggestedWeight: set.loadUnit.kilograms(set.load),
                    unit: set.unit == .reps ? nil : set.unit,
                    percentOfMax: set.loadUnit == .percentOfMax && set.load > 0 ? set.load : nil,
                    isMaxEffort: set.maxEffort
                )
            }
        }
        if !repScheme.isEmpty, segment == .round {
            return repScheme.map { PlannedSet(reps: $0) }
        }
        return nil
    }

    /// The session UI keeps one rounded kg pair; Rx wins, then a single load, then the first tier.
    private var weightConfiguration: WeightConfiguration? {
        let chosen = loads.first { $0.tier == .rx } ?? loads.first { $0.tier == .single } ?? loads.first
        guard let chosen, chosen.unit != .percentOfMax else { return nil }
        let men = chosen.unit.kilograms(chosen.men).map { Int($0.rounded()) }
        let women = chosen.unit.kilograms(chosen.women).map { Int($0.rounded()) }
        guard men != nil || women != nil else { return nil }
        return WeightConfiguration(men: men, women: women ?? men)
    }

    /// Everything the plan shows as a hint under the movement and has no field of its own.
    private var info: String? {
        var parts: [String] = []
        if !sets.isEmpty { parts.append(setsSummary) }
        if repRangeMax > 0, targetValue > 0 { parts.append("\(Int(targetValue))-\(repRangeMax) reps") }
        if maxEffort { parts.append("max effort") }
        if restAfterSetSec > 0 { parts.append("Rest: \(restAfterSetSec) s") }
        if !alternatives.isEmpty { parts.append("or " + alternatives.joined(separator: " / ")) }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    /// "4×8 @ 80 kg, 2×5 @ 70%" — consecutive identical sets collapse; a ladder stays "21-15-9".
    private var setsSummary: String {
        let labels = sets.map { $0.summary }
        let values = Set(labels)
        if values.count == labels.count, labels.count > 1, sets.allSatisfy({ $0.load == 0 }) {
            return sets.map { $0.maxEffort ? "max" : "\(Int($0.value))" }.joined(separator: "-")
        }
        var groups: [(label: String, count: Int)] = []
        for label in labels {
            if let last = groups.indices.last, groups[last].label == label {
                groups[last].count += 1
            } else {
                groups.append((label, 1))
            }
        }
        return groups.map { "\($0.count)×\($0.label)" }.joined(separator: ", ")
    }
}

// MARK: - Set / load helpers

extension ScannedSet {
    fileprivate var summary: String {
        let base = maxEffort ? "max" : (unit == .reps ? "\(Int(value))" : "\(Int(value)) \(unit.rawValue)")
        switch loadUnit {
        case .none: return base
        case .kg: return "\(base) @ \(Self.number(load)) kg"
        case .lb: return "\(base) @ \(Self.number(load)) lb"
        case .percentOfMax: return "\(base) @ \(Self.number(load))%"
        }
    }

    fileprivate static func number(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : "\(value)"
    }
}

extension ScannedLoad {
    fileprivate var loadTier: LoadTier {
        LoadTier(tier: tier, men: men > 0 ? men : nil, women: women > 0 ? women : nil, unit: unit)
    }

    fileprivate var summary: String {
        let pair = men == women || women == 0
            ? ScannedSet.number(men)
            : "\(ScannedSet.number(men))/\(ScannedSet.number(women))"
        let unitLabel = unit == .percentOfMax ? "%" : " \(unit.rawValue)"
        switch tier {
        case .single: return pair + unitLabel
        case .rx: return "Rx \(pair)\(unitLabel)"
        case .rxPlus: return "Rx+ \(pair)\(unitLabel)"
        case .pro: return "Pro \(pair)\(unitLabel)"
        case .scaled: return "Scaled \(pair)\(unitLabel)"
        }
    }
}

extension ScannedLoadUnit {
    fileprivate func kilograms(_ value: Double) -> Double? {
        guard value > 0 else { return nil }
        switch self {
        case .kg: return value
        case .lb: return (value * 0.45359237 * 2).rounded() / 2
        case .percentOfMax, .none: return nil
        }
    }
}

extension LoadTier.Unit {
    fileprivate func kilograms(_ value: Double) -> Double? {
        guard value > 0 else { return nil }
        switch self {
        case .kg: return value
        case .lb: return value * 0.45359237
        case .pood: return value * 16
        case .percentOfMax: return nil
        }
    }
}

extension WorkoutSessionNew {
    fileprivate func appendingNote(_ note: String) -> WorkoutSessionNew {
        var draft = WorkoutSessionDraft(workout: self)
        draft.notes = [draft.notes, note].compactMap { $0 }.joined(separator: "\n")
        return WorkoutSessionNew(id: id, draft: draft)
    }
}
