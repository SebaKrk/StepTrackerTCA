//
//  TrainingNotesPrompt.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/02/2026.
//

import Foundation
import SharedModels

/// Prompt templates for Claude API training notes generation.
enum TrainingNotesPrompt {

    // MARK: - System Prompts

    static let warmUpSystem =
        "You are a fitness coach. Generate a concise warm-up description (2-4 sentences) for the given workout. Respond with plain text only, no markdown."

    static let coolDownSystem =
        "You are a fitness coach. Generate a concise cool-down description (2-4 sentences) for the given workout. Respond with plain text only, no markdown."

    // MARK: - User Prompts

    static func warmUpUser(workouts: [WorkoutSessionNew], durationMinutes: Int?) -> String {
        buildUserPrompt(workouts: workouts, durationMinutes: durationMinutes, type: .warmUp)
    }

    static func coolDownUser(workouts: [WorkoutSessionNew], durationMinutes: Int?) -> String {
        buildUserPrompt(workouts: workouts, durationMinutes: durationMinutes, type: .coolDown)
    }

    // MARK: - Private

    private enum NoteType { case warmUp, coolDown }

    private static func buildUserPrompt(
        workouts: [WorkoutSessionNew],
        durationMinutes: Int?,
        type: NoteType
    ) -> String {
        var lines = ["Workout:"]
        for workout in workouts {
            lines.append("- \(workout.name) (\(workout.type))")
            for exercise in workout.exercises {
                lines.append("  • \(exercise.displayName)")
            }
        }
        if let duration = durationMinutes {
            switch type {
            case .warmUp:   lines.append("Warm-up duration: \(duration) min")
            case .coolDown: lines.append("Cool-down duration: \(duration) min")
            }
        }
        let verb = type == .warmUp ? "warm-up" : "cool-down"
        lines.append("\nGenerate a \(verb) routine for this workout.")
        return lines.joined(separator: "\n")
    }
}
