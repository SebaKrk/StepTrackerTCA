//
//  ExtractedWorkout+Mapper.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 12/02/2026.
//

import Foundation

extension ExtractedWorkout {

    /// Converts ExtractedWorkout to TrainingSession for workout execution.
    ///
    /// The LLM-extracted `date` string is deliberately IGNORED: the model
    /// hallucinates a date (e.g. "2024-01-01") when the photo has none, and a
    /// plausible-but-wrong date is worse than an honest default. The session
    /// is dated to the scan moment — the user adjusts it consciously in the
    /// editor when the plan is for another day.
    public func toTrainingSession(scanDate: Date = Date()) -> TrainingSession {
        // Extract warmup section (take first if duplicates)
        let warmUp = sections
            .first(where: { $0.type == .warmup })?
            .toWarmUpSession()

        // Extract workout sections (strength + conditioning + mobility).
        // Mobility must be a full workout section — warmup/cooldown mapping
        // keeps only the free-text description and would drop its exercises.
        let workouts = sections
            .filter { $0.type == .strength || $0.type == .conditioning || $0.type == .mobility }
            .map { $0.toWorkoutSessionNew() }

        // Extract cooldown section (take first if duplicates)
        let coolDown = sections
            .first(where: { $0.type == .cooldown })?
            .toCoolDownSession()


        return TrainingSession(
            date: scanDate,
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

        // Determine workout type: the section's format hint (`rounds`) wins for
        // WOD sections, resolved through `ExerciseWorkoutType.aliases` so every
        // format — AMRAP, EMOM, Tabata, … — is recognised from one source of
        // truth. A round hint with no known keyword ("8 rounds", "5") = For Time.
        let hinted: ExerciseWorkoutType? = rounds.map { ExerciseWorkoutType.matching($0) ?? .forTime }

        let workoutType: ExerciseWorkoutType
        switch type {
        case .mobility:
            // Format-less by definition — "stretch ×5 per side" must not turn
            // a rehab section into a timed For Time WOD.
            workoutType = .mobility
        case .strength:
            // Differentiate based on first exercise category
            let firstCategory = exerciseSessions.first?.type.category
            workoutType = hinted ?? (firstCategory == .olympicLifting ? .olympicWeightlifting : .strength)
        case .conditioning, .warmup, .cooldown, .transition:
            workoutType = hinted ?? .amrap
        }

        // Round count only makes sense for round-based formats; for AMRAP/EMOM the
        // trailing number is the time cap (already in `timeCapMinutes`), not rounds.
        // Rep schemes like "21-15-9" are not a round count, so skip dashed strings.
        let roundsInt: Int?
        switch workoutType {
        case .forTime, .tabata:
            roundsInt = rounds.flatMap { $0.contains("-") ? nil : $0.firstInteger }
        case .amrap, .emom, .strength, .olympicWeightlifting, .mobility:
            roundsInt = nil
        }

        // Timer-required formats (AMRAP/EMOM/Tabata) fall back to the type's
        // default cap when the plan didn't state one; For Time stays uncapped.
        let cap = timeCapMinutes
            ?? (workoutType.isTimerRequired ? workoutType.defaultTimeCapMinutes : nil)

        return WorkoutSessionNew(
            name: name ?? type.rawValue.capitalized,
            type: workoutType,
            timeCap: cap,
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
    /// Delegates to the shared catalog matcher so scan-time mapping and the
    /// one-time re-match job resolve names identically.
    fileprivate static func from(name: String) -> ExerciseType {
        let matched = ExerciseType.matched(fromRawName: name)
        #if DEBUG
        if matched == .unknown {
            // Fallback to .unknown - preserve original name in customName
            print("⚠️ [Mapper] Unknown exercise '\(name)' → using '.unknown'")
        }
        #endif
        return matched
    }

}

// MARK: - Weight Parsing

extension String {

    /// First integer embedded in the string ("8 rounds" → 8, "Tabata 8" → 8,
    /// "AMRAP" → nil). Robust to descriptive text around the number.
    fileprivate var firstInteger: Int? {
        components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap(Int.init)
            .first
    }

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
            #if DEBUG
            print("⚠️ [Mapper] Failed to parse weight '\(self)' → using nil")
            #endif
            return nil
        }

        return WeightConfiguration(men: men, women: women)
    }

}
