//
//  ClaudeWorkoutMapper.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 15/02/2026.
//

import Foundation
import SharedModels

/// Maps Claude API response to ExtractedWorkout.
public struct ClaudeWorkoutMapper {

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Maps Claude API response to ExtractedWorkout.
    public func map(_ response: ClaudeAPIResponse, rawText: String) throws -> ExtractedWorkout {
        // Extract JSON from content (remove markdown code fence if present)
        guard let contentText = response.content.first?.text else {
            throw ClaudeAPIError.emptyResponse
        }

        let jsonString = try extractJSON(from: contentText)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ClaudeAPIError.invalidJSON
        }

        let workoutResponse = try JSONDecoder().decode(ClaudeWorkoutResponse.self, from: jsonData)

        // Convert to ExtractedWorkout
        let sections = workoutResponse.sections.map { convertSection($0) }

        // Use today's date if Claude didn't extract one from OCR
        let dateString = workoutResponse.date ?? {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate]
            return formatter.string(from: Date())
        }()

        return ExtractedWorkout(
            name: workoutResponse.name,
            date: dateString,
            totalEstimatedMinutes: workoutResponse.totalEstimatedMinutes,
            rawText: rawText,
            sections: sections
        )
    }

    // MARK: - Private Methods

    /// Extracts JSON from markdown code fence (````json...```).
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

    /// Converts Claude workout section to domain model.
    private func convertSection(_ section: ClaudeWorkoutSection) -> WorkoutSection {
        let exercises = section.exercises?.map { convertExercise($0) }

        return WorkoutSection(
            type: SectionType(rawValue: section.type) ?? .warmup,
            name: section.name,
            durationMinutes: section.durationMinutes,
            description: section.description,
            timeCapMinutes: section.timeCapMinutes,
            rounds: section.rounds,
            exercises: exercises,
            notes: section.notes
        )
    }

    /// Converts Claude exercise to domain model.
    private func convertExercise(_ exercise: ClaudeExercise) -> ExtractedExercise {
        let sets = exercise.sets?.map { convertSet($0) }

        return ExtractedExercise(
            name: exercise.name,
            reps: exercise.reps,
            sets: sets,
            scalingOptions: exercise.scalingOptions
        )
    }

    /// Converts Claude exercise set to domain model.
    private func convertSet(_ set: ClaudeExerciseSet) -> ExerciseSet {
        ExerciseSet(
            setNumber: set.setNumber,
            reps: set.reps,
            intensity: set.intensity,
            restSeconds: set.restSeconds
        )
    }
}
