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
        // Parse date from "yyyy-MM-dd" string
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let parsedDate = dateFormatter.date(from: date) ?? Date()

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
            activity: .crossTraining,
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
            description: description ?? notes
        )
    }

    fileprivate func toCoolDownSession() -> CoolDownSession {
        CoolDownSession(
            goal: .timeLimit,
            time: durationMinutes,
            description: description ?? notes
        )
    }

    fileprivate func toWorkoutSessionNew() -> WorkoutSessionNew {
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
        } else {
            // Default: strength = forTime, conditioning = amrap
            workoutType = type == .strength ? .forTime : .amrap
        }

        // Parse rounds (e.g. "5" → 5, "AMRAP" → nil)
        let roundsInt: Int?
        if let roundsString = rounds, let int = Int(roundsString) {
            roundsInt = int
        } else {
            roundsInt = nil
        }

        // Map exercises
        let exerciseSessions = exercises?
            .map { $0.toExerciseSession() } ?? []

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

        // Determine target from reps or sets
        let target: ExerciseTarget?
        if let reps = reps, sets == nil {
            // Simple rep target (e.g., AMRAP exercises: "16 swings", "8 HSPU")
            target = .reps(reps)
        } else if sets != nil {
            // Strength exercises with set schemes (e.g., "4×5 @ 50-60%")
            // Target is nil - full info is in 'info' string with percentages
            target = nil
        } else {
            target = nil
        }

        // Parse weight from scalingOptions (e.g. "24/16" → WeightConfiguration)
        let weight = scalingOptions?.parseWeight()

        // Group sets into SetScheme (e.g., 4×5 @ 50-60%, 3×4 @ 60-70%)
        let setSchemes: [SetScheme]? = sets.map { sets in
            let grouped = Dictionary(grouping: sets) { set in
                "\(set.reps)|\(set.intensity ?? "")"
            }

            return grouped
                .sorted { $0.value.first?.setNumber ?? 0 < $1.value.first?.setNumber ?? 0 }
                .map { _, group in
                    SetScheme(
                        count: group.count,
                        reps: group.first?.reps ?? 0,
                        intensity: group.first?.intensity
                    )
                }
        }

        // Build info string from scaling only (sets are now in SetScheme)
        let info = scalingOptions.map { "Scaling: \($0)" }

        return ExerciseSession(
            type: exerciseType,
            target: target,
            weight: weight,
            sets: setSchemes,
            info: info
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

        // Fallback to airSquat with warning
        print("⚠️ [Mapper] Unknown exercise '\(name)' → using fallback '.airSquat'")
        return .airSquat
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
