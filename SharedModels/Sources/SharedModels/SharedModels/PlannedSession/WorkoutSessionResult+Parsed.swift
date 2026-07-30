//
//  WorkoutSessionResult+Parsed.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 10/05/2026.
//

import Foundation

/// Structured view of a `WorkoutSessionResult.description` produced for cleaner UI rendering.
///
/// The raw description is plain text snapshotted from the training plan, e.g.:
/// ```
/// 15 min cap
/// 200m Running
/// Info: Scaling: fast pace
/// 8x Overhead Squat
/// Info: Scaling: 50/35 kg
/// ```
///
/// `ParsedWodDescription` lifts this into a typed structure so views can render
/// hierarchy (time-cap badge, exercise rows, scaling captions) without string parsing.
public struct ParsedWodDescription: Equatable {

    public struct Item: Equatable {
        /// Main exercise line, e.g. "8x Overhead Squat" or "200m Running".
        public let line: String
        /// Trailing scaling/info note attached to this exercise, e.g. "50/35 kg" or "fast pace".
        /// Stripped of the "Info: Scaling:" / "Info:" prefix.
        public let scaling: String?
    }

    /// Time cap line if present (e.g. "15 min cap", "20 min CAP"). `nil` if not detected.
    public let timeCap: String?

    /// One item per exercise in the WOD description.
    public let items: [Item]
}

public extension WorkoutSessionResult {

    /// Approximates the WOD type from the saved `scoreResult`, used when the original
    /// `TrainingSession` is not available (e.g., when displaying historical results).
    var derivedWodType: ExerciseWorkoutType {
        switch scoreResult {
        case .forTime, .timeCap: return .forTime
        case .amrap:             return .amrap
        case .forLoad:           return .strength
        case .forReps:           return .tabata
        case .completed, .custom: return .forTime
        }
    }

    /// Parses `description` into a `ParsedWodDescription`.
    ///
    /// Heuristics:
    /// - First non-empty line containing "cap" (case-insensitive) and appearing before
    ///   any exercise line → `timeCap`.
    /// - Lines starting with `Info: Scaling:` or `Info:` → attached as `scaling` to the
    ///   most recently seen exercise line.
    /// - Other non-empty lines → new `Item` with `line` text.
    var parsedDescription: ParsedWodDescription {
        let lines = description
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var timeCap: String?
        var items: [ParsedWodDescription.Item] = []
        var pendingLine: String?

        func flushPending() {
            if let pending = pendingLine {
                items.append(.init(line: pending, scaling: nil))
                pendingLine = nil
            }
        }

        func attachScaling(_ value: String) {
            if let pending = pendingLine {
                items.append(.init(line: pending, scaling: value))
                pendingLine = nil
            } else if !items.isEmpty {
                let last = items.removeLast()
                items.append(.init(line: last.line, scaling: value))
            }
        }

        for line in lines {
            let lower = line.lowercased()

            // Time-cap detection — only at the very top, before any exercise line.
            if timeCap == nil, items.isEmpty, pendingLine == nil, lower.contains("cap") {
                timeCap = line
                continue
            }

            if lower.hasPrefix("info: scaling:") {
                let value = String(line.dropFirst("Info: Scaling:".count))
                    .trimmingCharacters(in: .whitespaces)
                attachScaling(value)
                continue
            }

            if lower.hasPrefix("info:") {
                let value = String(line.dropFirst("Info:".count))
                    .trimmingCharacters(in: .whitespaces)
                attachScaling(value)
                continue
            }

            if lower.hasPrefix("scaling:") {
                let value = String(line.dropFirst("Scaling:".count))
                    .trimmingCharacters(in: .whitespaces)
                attachScaling(value)
                continue
            }

            // New exercise line — flush previous pending without scaling first.
            flushPending()
            pendingLine = line
        }
        flushPending()

        return ParsedWodDescription(timeCap: timeCap, items: items)
    }
}
