//
//  ClaudeWorkoutMapper.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation
import SharedModels

/// Maps Claude API response to ExtractedWorkout.
///
/// Extracts JSON from Claude response and decodes it directly to ExtractedWorkout.
public struct ClaudeWorkoutMapper {

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Maps Claude API response to ExtractedWorkout.
    public func map(_ response: ClaudeAPIResponse) throws -> ExtractedWorkout {
        // Extract JSON from content (remove markdown code fence if present)
        guard let contentText = response.content.first?.text else {
            throw ClaudeAPIError.emptyResponse
        }

        #if DEBUG
        print("🤖 [ClaudeWorkoutMapper] RAW AI RESPONSE:\n\(contentText)\n")
        #endif

        let jsonString = try extractJSON(from: contentText)

        #if DEBUG
        print("🧹 [ClaudeWorkoutMapper] CLEANED JSON:\n\(jsonString)\n")
        #endif

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidJSON
        }

        // Decode Claude JSON directly to ExtractedWorkout
        let workout = try JSONDecoder().decode(ExtractedWorkout.self, from: jsonData)

        #if DEBUG
        debugLog(workout)
        #endif

        return workout
    }

    // MARK: - Private Methods

    #if DEBUG
    /// Prints a structural summary of a decoded workout — sections, exercises,
    /// and per-exercise set counts. Designed to surface „missing sets" bugs at a glance.
    private func debugLog(_ workout: ExtractedWorkout) {
        print("📦 [ClaudeWorkoutMapper] DECODED workout: \"\(workout.name)\" — \(workout.sections.count) sections")
        for (sectionIndex, section) in workout.sections.enumerated() {
            let label = section.name ?? "(no name)"
            let exerciseCount = section.exercises?.count ?? 0
            print("  └─ Section[\(sectionIndex)] type=\(section.type.rawValue) name=\"\(label)\" exercises=\(exerciseCount)")
            for (exerciseIndex, exercise) in (section.exercises ?? []).enumerated() {
                let setsCount = exercise.sets?.count ?? 0
                let scaling = exercise.scalingOptions ?? "—"
                print("       ├─ Exercise[\(exerciseIndex)] \"\(exercise.name)\" sets=\(setsCount) scaling=\"\(scaling)\"")
                for set in (exercise.sets ?? []) {
                    let reps = set.reps.map { "\($0)" } ?? "nil"
                    let intensity = set.intensity ?? "—"
                    let rest = set.restSeconds.map { "\($0)s" } ?? "—"
                    print("       │    • set#\(set.setNumber) reps=\(reps) intensity=\"\(intensity)\" rest=\(rest)")
                }
            }
        }
        print("")
    }
    #endif

    /// Extracts JSON from markdown code fence (```json...```).
    private func extractJSON(from text: String) throws -> String {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return jsonString
    }
}
