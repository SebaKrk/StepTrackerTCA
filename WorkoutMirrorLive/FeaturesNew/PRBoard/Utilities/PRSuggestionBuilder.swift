//
//  PRSuggestionBuilder.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 05/09/2026.
//

import Foundation
import SharedModels

/// One "add this to the PR Board" candidate derived from the Summary draft.
struct PRSuggestion: Identifiable, Equatable {

    /// Catalog movement the suggestion targets (weight-scored, bridged).
    let movement: PRMovement

    /// Heaviest set weight entered this workout.
    let kilograms: Double

    /// Current board PR to beat; nil = the movement has no entries yet.
    let previousBest: Double?

    var id: String { movement.id }
}

/// Pure derivation of PR suggestions from the draft results + board history.
/// Strength-only by design — benchmarks and timed cardio are tested separately
/// and entered by hand (auto-detection parked in the roadmap, iteration 2).
enum PRSuggestionBuilder {

    static func suggestions(
        results: [WorkoutSessionResult],
        entries: [PREntry]
    ) -> [PRSuggestion] {
        // Heaviest entered weight per bridged movement, across all cards —
        // per-set entries first, the single-field `actualWeight` as fallback
        // (heavy singles land there and are the likeliest PRs of all).
        var candidates: [String: (movement: PRMovement, kilograms: Double)] = [:]
        var order: [String] = []
        for result in results {
            for exercise in result.exercises {
                guard
                    let type = exercise.exerciseType,
                    let movement = weightMovement(for: type),
                    let heaviest = exercise.sets?.compactMap(\.weight).max() ?? exercise.actualWeight,
                    heaviest > 0
                else { continue }
                if let current = candidates[movement.id] {
                    if heaviest > current.kilograms {
                        candidates[movement.id] = (movement, heaviest)
                    }
                } else {
                    candidates[movement.id] = (movement, heaviest)
                    order.append(movement.id)
                }
            }
        }

        return order.compactMap { movementId in
            guard let candidate = candidates[movementId] else { return nil }
            let history = entries.filter { $0.movementId == movementId }
            let best = PRResolver.summary(for: candidate.movement, entries: history).best
            guard let best else {
                // No entries yet — a first result is worth seeding the board.
                return PRSuggestion(
                    movement: candidate.movement,
                    kilograms: candidate.kilograms,
                    previousBest: nil
                )
            }
            // A mismatched-type best (D4 fallback) is not comparable to kilograms.
            guard case let .weight(bestKilograms) = best.score else { return nil }
            guard candidate.kilograms > bestKilograms else { return nil }
            return PRSuggestion(
                movement: candidate.movement,
                kilograms: candidate.kilograms,
                previousBest: bestKilograms
            )
        }
    }

    /// Explicit primary movement for ambiguous reverse bridges — catalog order
    /// is NOT a contract (a reorder must never silently retarget suggestions).
    private static let primaryMovementId: [ExerciseType: String] = [
        .deadlift: "deadlift"
    ]

    /// Reverse bridge lookup. Ambiguous types resolve only through the pinned
    /// primary above; an unpinned ambiguity yields no suggestion (conservative).
    private static func weightMovement(for type: ExerciseType) -> PRMovement? {
        if let pinnedId = primaryMovementId[type] {
            return PRCatalog.movement(id: pinnedId)
        }
        let matches = PRCatalog.movements.filter {
            $0.scoreType == .weight && $0.exerciseType == type
        }
        return matches.count == 1 ? matches.first : nil
    }
}
