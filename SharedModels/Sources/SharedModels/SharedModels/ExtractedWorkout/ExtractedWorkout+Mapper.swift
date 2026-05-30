//
//  ExtractedWorkout+Mapper.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation

extension ExtractedWorkout {

    /// Converts ExtractedWorkout to TrainingSession for workout execution.
    public func toTrainingSession() -> TrainingSession {
        // Parse date from "yyyy-MM-dd" string (fallback to today if nil or invalid)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let parsedDate = date.flatMap { dateFormatter.date(from: $0) } ?? Date()

        // Extract warmup section (take first if duplicates)
        let warmUp = sections
            .first(where: { $0.type == .warmup })?
            .toWarmUpSession()

        // Extract workout sections (strength + conditioning)
        let workouts = sections
            .filter { $0.type == .strength || $0.type == .conditioning }
            .map { $0.toWorkoutSessionNew() }

        // Extract cooldown section (take first if duplicates)
        let coolDown = sections
            .first(where: { $0.type == .cooldown })?
            .toCoolDownSession()


        return TrainingSession(
            date: parsedDate,
            title: name,
            activity: workoutType,
            location: .indoor,
            warmUp: warmUp,
            workouts: workouts,
            coolDown: coolDown
        )
    }

}

// MARK: - WorkoutSection Mappers

extension WorkoutSection {

    fileprivate func toWarmUpSession() -> WarmUpSession {
        WarmUpSession(
            goal: .timeLimit,
            time: durationMinutes,
            description: description ?? ""
        )
    }

    fileprivate func toCoolDownSession() -> CoolDownSession {
        CoolDownSession(
            goal: .timeLimit,
            time: durationMinutes,
            description: description ?? ""
        )
    }

    fileprivate func toWorkoutSessionNew() -> WorkoutSessionNew {
        // Map exercises first (needed for workout type inference)
        let exerciseSessions = exercises?
            .map { $0.toExerciseSession() } ?? []

        // Determine workout type from section
        let workoutType: ExerciseWorkoutType
        if let roundsString = rounds?.uppercased() {
            if roundsString.contains("AMRAP") {
                workoutType = .amrap
            } else if roundsString.contains("EMOM") {
                workoutType = .emom
            } else {
                workoutType = .forTime
            }
        } else if type == .strength {
            // Differentiate based on first exercise category
            let firstCategory = exerciseSessions.first?.type.category
            workoutType = firstCategory == .olympicLifting ? .olympicWeightlifting : .strength
        } else {
            workoutType = .amrap
        }

        // Parse rounds (e.g. "5" → 5, "AMRAP" → nil)
        let roundsInt: Int?
        if let roundsString = rounds, let int = Int(roundsString) {
            roundsInt = int
        } else {
            roundsInt = nil
        }

        return WorkoutSessionNew(
            name: name ?? type.rawValue.capitalized,
            type: workoutType,
            timeCap: timeCapMinutes,
            rounds: roundsInt,
            exercises: exerciseSessions
        )
    }

}

// MARK: - ExtractedExercise Mapper

extension ExtractedExercise {

    fileprivate func toExerciseSession() -> ExerciseSession {
        // Map exercise name to ExerciseType
        let exerciseType = ExerciseType.from(name: name)

        // Preserve original name for .unknown exercises
        let customName = (exerciseType == .unknown) ? name : nil

        // Determine target from reps + unit
        let target: ExerciseTarget?
        if let reps = reps, sets == nil {
            switch unit?.lowercased() {
            case "seconds": target = .seconds(reps)
            case "minutes": target = .minutes(reps)
            case "meters":  target = .meters(reps)
            case "calories": target = .calories(reps)
            case "laps":    target = .laps(reps)
            default:        target = .reps(reps)  // "reps" or nil
            }
        } else if sets != nil {
            // Strength exercises with set schemes (e.g., "4×5 @ 50-60%")
            target = nil
        } else {
            target = nil
        }

        // Parse weight from scalingOptions (e.g. "24/16" → WeightConfiguration)
        let weight = scalingOptions?.parseWeight()

        // Convert AI sets → structured PlannedSet array (used by SetInputView post-workout).
        let plannedSets: [PlannedSet]? = sets.flatMap { sets -> [PlannedSet]? in
            let mapped = sets.compactMap { set -> PlannedSet? in
                guard let reps = set.reps else { return nil }
                return PlannedSet(
                    reps: reps,
                    suggestedWeight: PlannedSet.extractWeightKg(from: set.intensity)
                )
            }
            return mapped.isEmpty ? nil : mapped
        }

        // Convert AI sets → readable text (e.g., "4×5 @ 50-60%, 3×4 @ 60-70%")
        // for display in plan preview / Edit WOD / Activity Details before workout starts.
        let setsInfo: String? = sets.flatMap { sets -> String? in
            let validSets = sets.filter { $0.reps != nil }
            guard !validSets.isEmpty else { return nil }
            let grouped = Dictionary(grouping: validSets) { "\($0.reps!)|\($0.intensity ?? "")" }
            let schemes = grouped
                .sorted { $0.value.first?.setNumber ?? 0 < $1.value.first?.setNumber ?? 0 }
                .map { _, group -> String in
                    var desc = "\(group.count)×\(group.first!.reps!)"
                    if let intensity = group.first?.intensity { desc += " @ \(intensity)" }
                    return desc
                }
            return schemes.joined(separator: ", ")
        }

        // Combine sets text and scaling options into one info field (display layer).
        let scalingInfo = scalingOptions.map { "Scaling: \($0)" }
        let infoParts = [setsInfo, scalingInfo].compactMap { $0 }
        let info: String? = infoParts.isEmpty ? nil : infoParts.joined(separator: "\n")

        return ExerciseSession(
            type: exerciseType,
            customName: customName,
            target: target,
            weight: weight,
            info: info,
            plannedSets: plannedSets
        )
    }

}

// MARK: - ExerciseType Mapping

extension ExerciseType {

    /// Maps exercise name string to ExerciseType enum using aliases.
    fileprivate static func from(name: String) -> ExerciseType {
        let normalized = name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Check all ExerciseType cases and their aliases
        for exerciseType in ExerciseType.allCases {
            // Check rawValue
            if exerciseType.rawValue.lowercased() == normalized {
                return exerciseType
            }

            // Check aliases
            if exerciseType.aliases.contains(where: { $0.lowercased() == normalized }) {
                return exerciseType
            }
        }

        // SPECIAL CASE: Distance-based exercises (e.g., "1,600-meter run", "5km row")
        // Extract exercise type from suffix
        if normalized.hasSuffix("run") || normalized.contains("meter run") || normalized.contains("km run") || normalized.contains("mile run") {
            print("⚠️ [Mapper] Distance-based exercise '\(name)' → extracting 'running'")
            return .running
        }
        if normalized.hasSuffix("row") || normalized.contains("meter row") || normalized.contains("km row") {
            print("⚠️ [Mapper] Distance-based exercise '\(name)' → extracting 'rowing'")
            return .rowing
        }
        if normalized.hasSuffix("bike") || normalized.contains("meter bike") || normalized.contains("km bike") {
            print("⚠️ [Mapper] Distance-based exercise '\(name)' → extracting 'cycling'")
            return .cycling
        }

        // Fallback to .unknown - preserve original name in customName
        print("⚠️ [Mapper] Unknown exercise '\(name)' → using '.unknown'")
        return .unknown
    }

}

// MARK: - Weight Parsing

extension String {

    /// Parses weight scaling options like "24/16" or "24/16, 28/20" to WeightConfiguration.
    fileprivate func parseWeight() -> WeightConfiguration? {
        // Take first option (RX weight)
        let firstOption = components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces)

        guard let option = firstOption else { return nil }

        // Parse "24/16" format
        let parts = option.components(separatedBy: "/")
        guard parts.count == 2,
              let men = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let women = Int(parts[1].trimmingCharacters(in: .whitespaces)) else {
            print("⚠️ [Mapper] Failed to parse weight '\(self)' → using nil")
            return nil
        }

        return WeightConfiguration(men: men, women: women)
    }

}
