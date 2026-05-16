//
//  PlannedSet+Parser.swift
//  SharedModels
//

import Foundation

extension PlannedSet {

    /// Parses set schemes from a free-text string into structured `[PlannedSet]`.
    ///
    /// Recognises patterns: "5x5", "5×5", "5x5 @80", "5x5 @80kg", "5x5 @ 80 kg",
    /// "4×6 @ 60kg, 2×4 @ 70kg", "5×5\n3×3 @ 90kg" (comma / newline separated chunks).
    ///
    /// Returns nil when no `<sets>x<reps>` pattern is found. Caller can then preserve
    /// existing plannedSets or fall back to single-row input mode.
    ///
    /// Sanity caps `setsCount ≤ 20`, `reps ≤ 100` protect against false positives
    /// (e.g. accidental numeric matches in free-text notes).
    public static func parse(from info: String) -> [PlannedSet]? {
        let chunks = info.split(whereSeparator: { $0 == "," || $0 == "\n" })
        let pattern = #"(\d+)\s*[xX×]\s*(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        var result: [PlannedSet] = []
        for chunk in chunks {
            let str = String(chunk)
            let nsrange = NSRange(str.startIndex..., in: str)
            guard
                let match = regex.firstMatch(in: str, range: nsrange),
                let setsRange = Range(match.range(at: 1), in: str),
                let repsRange = Range(match.range(at: 2), in: str),
                let setsCount = Int(str[setsRange]),
                let reps = Int(str[repsRange]),
                setsCount > 0, setsCount <= 20,
                reps > 0, reps <= 100
            else { continue }

            let weight = PlannedSet.extractWeightKg(from: str)
            let entry = PlannedSet(reps: reps, suggestedWeight: weight)
            result.append(contentsOf: Array(repeating: entry, count: setsCount))
        }
        return result.isEmpty ? nil : result
    }

    /// Extracts a kilogram value from an intensity / scheme string.
    ///
    /// Accepts either `<number>kg` literal or `@<number>` shorthand (user-friendly,
    /// matches how schemes are commonly typed in Notes — "5x5 @80").
    /// Returns nil for percent-based prescriptions ("50-60%") or bodyweight ("BW").
    /// Requires explicit `@` or `kg` marker — prevents false positives like
    /// "Rest 2 min" being parsed as 2 kg.
    public static func extractWeightKg(from intensity: String?) -> Double? {
        guard let intensity else { return nil }

        // Skip percent-based prescriptions explicitly.
        if intensity.contains("%") { return nil }

        let patterns = [
            #"(\d+(?:\.\d+)?)\s*kg"#,
            #"@\s*(\d+(?:\.\d+)?)"#
        ]

        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { continue }
            let range = NSRange(intensity.startIndex..., in: intensity)
            if let match = regex.firstMatch(in: intensity, range: range),
               let captured = Range(match.range(at: 1), in: intensity),
               let value = Double(intensity[captured]) {
                return value
            }
        }
        return nil
    }
}
