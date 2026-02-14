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
        if let reps = reps {
            target = .reps(reps)
        } else if let sets = sets, let firstSet = sets.first {
            // For set schemes like "4×5", use reps from first scheme
            target = .reps(firstSet.reps)
        } else {
            target = nil
        }

        // Parse weight from scalingOptions (e.g. "24/16" → WeightConfiguration)
        let weight = scalingOptions?.parseWeight()

        // Build info string from sets and scaling
        var infoComponents: [String] = []

        if let sets = sets {
            let setsString = sets.map { set in
                var s = "\(set.setNumber)×\(set.reps)"
                if let intensity = set.intensity {
                    s += " @ \(intensity)"
                }
                return s
            }.joined(separator: ", ")
            infoComponents.append(setsString)
        }

        if let scalingOptions = scalingOptions {
            infoComponents.append("Scaling: \(scalingOptions)")
        }

        let info = infoComponents.isEmpty ? nil : infoComponents.joined(separator: " | ")

        return ExerciseSession(
            type: exerciseType,
            target: target,
            weight: weight,
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
