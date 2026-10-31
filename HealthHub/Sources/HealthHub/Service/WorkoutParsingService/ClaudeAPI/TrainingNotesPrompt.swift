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

    // A cue the athlete glances at on the gym floor, not an article: the length is the whole point.
    static let warmUpSystem =
        "You are a fitness coach. Write a warm-up cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to prime (joints, muscles, movement pattern) for these blocks. Lines 2–3 list 2–3 movements, each with a time or rep count. No introduction, no explanations, plain text only, no markdown, no bullets."

    static let coolDownSystem =
        "You are a fitness coach. Write a cool-down cue for the given workout: at most 3 short lines, about 40 words in total. Line 1 names what to release after these blocks. Lines 2–3 list 2–3 stretches or breathing drills, each with a time. No introduction, no explanations, plain text only, no markdown, no bullets."

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
        lines.append("\nWrite the \(verb) cue for this workout.")
        return lines.joined(separator: "\n")
    }
}
