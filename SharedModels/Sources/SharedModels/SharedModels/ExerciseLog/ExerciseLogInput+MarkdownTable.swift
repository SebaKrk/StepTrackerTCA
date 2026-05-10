//
//  ExerciseLogInput+MarkdownTable.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 10/05/2026.
//

import Foundation

public extension Array where Element == ExerciseLogInput {

    /// Renders the exercises as a markdown table for display via Textual or any
    /// markdown renderer. Two formats are produced based on per-set presence:
    ///
    /// - **WOD (simple):** `Exercise | Result | kg` — one row per exercise.
    /// - **Strength (per-set):** exercise name as header + `Set | Reps | kg` rows.
    ///
    /// Unmatched exercises (no `ExerciseType` from the catalog or `.unknown`) get
    /// a trailing `*` suffix so missing catalog entries are visible during dev.
    func markdownTable() -> String {
        let hasStrengthSets = contains { $0.sets != nil }
        if hasStrengthSets {
            return strengthMarkdownTable()
        } else {
            return wodMarkdownTable()
        }
    }

    /// WOD table: one row per exercise.
    private func wodMarkdownTable() -> String {
        let hasWeight = contains { $0.actualWeight != nil }

        var md = ""
        if hasWeight {
            md += "| Exercise | Result | kg |\n"
            md += "|----------|--------|----|\n"
        } else {
            md += "| Exercise | Result |\n"
            md += "|----------|--------|\n"
        }

        for exercise in self {
            let name = exercise.displayName + (exercise.isUnmatched ? " *" : "")
            let reps = exercise.actualReps ?? "—"
            if hasWeight {
                let w = exercise.actualWeight.map { "\(Int($0))" } ?? "—"
                md += "| \(name) | \(reps) | \(w) |\n"
            } else {
                md += "| \(name) | \(reps) |\n"
            }
        }

        return md
    }

    /// Strength table: per-set rows with set number, reps, weight.
    /// Falls back to a single bold line when no `sets` are present.
    private func strengthMarkdownTable() -> String {
        var md = ""

        for exercise in self {
            let name = exercise.displayName + (exercise.isUnmatched ? " *" : "")

            if let sets = exercise.sets, !sets.isEmpty {
                md += "**\(name)**\n\n"
                md += "| Set | Reps | kg |\n"
                md += "|-----|------|----|\n"
                for (i, entry) in sets.enumerated() {
                    let w = entry.weight.map { "\(Int($0))" } ?? "—"
                    md += "| \(i + 1) | \(entry.reps) | \(w) |\n"
                }
                md += "\n"
            } else {
                let reps = exercise.actualReps ?? "—"
                let w = exercise.actualWeight.map { " · \(Int($0))kg" } ?? ""
                md += "**\(name):** \(reps)\(w)\n\n"
            }
        }

        return md
    }
}
