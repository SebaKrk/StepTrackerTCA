//
//  EnteredValue.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 08/11/2026.
//

import Foundation

/// Reading back what a result field holds: a number with the target's unit stuck to it.
///
/// Values are stored the way `ExerciseTarget.compactString` writes them — "54x",
/// "20 cal", "400m" — so every screen that wants the number out of one was parsing
/// the string for itself. This is the one place that READS the shape; `ExerciseTarget`
/// writes it, and the two part ways for rounds and laps.
public enum EnteredValue {

    /// The leading integer: "54x" → 54, "20 cal" → 20, "done" → nil.
    public static func number(_ raw: String) -> Int? {
        Int(raw.trimmingCharacters(in: .whitespaces).prefix(while: \.isNumber))
    }

    /// The value without its unit, as an editable field shows it: "20 cal" → "20".
    ///
    /// Keeps dashes and dots, so a ladder written as "21-15-9" and a decimal survive.
    public static func numericPrefix(_ raw: String?) -> String {
        guard let raw else { return "" }
        return String(raw.prefix { $0.isNumber || $0 == "-" || $0 == "." })
    }

    /// Whatever follows that number: "20 cal" → "cal", "54x" → "x", "54" → "".
    private static func unit(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let digits = trimmed.prefix(while: \.isNumber)
        return trimmed.dropFirst(digits.count).trimmingCharacters(in: .whitespaces)
    }

    /// Whether the value counts plain repetitions rather than calories, metres or seconds.
    ///
    /// Reps are written bare or with a trailing "x", so both read as repetitions.
    public static func isPlainReps(_ raw: String) -> Bool {
        let unit = unit(raw)
        return unit.isEmpty || unit == "x"
    }
}
