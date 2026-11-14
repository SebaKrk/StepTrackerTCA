//
//  NicknameSuggestion.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 14/11/2026.
//

import Foundation

/// Proposes the name other people will see, from the name the person entered.
///
/// A proposal, never a silent substitution: the welcome screen puts it in the
/// field so it can be read and changed before anyone else sees it. Collisions
/// are left to the person to resolve, since a device cannot know who else is
/// in the room.
public enum NicknameSuggestion {

    /// How many letters of the first name the proposal keeps.
    private static let namePrefixLength = 3

    /// Builds the proposal, or an empty string when there is no name yet.
    ///
    /// Diacritics are kept — the names are Polish and so are the people reading
    /// them.
    ///
    /// - Parameters:
    ///   - name: First name as entered
    ///   - surname: Last name as entered, may be empty
    /// - Returns: Something like `SebŚ`, `JanK` or `Ewa`
    public static func make(name: String, surname: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { return "" }

        let prefix = String(trimmedName.prefix(namePrefixLength))

        guard let initial = surname
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .first else {
            return prefix
        }

        return prefix + String(initial).uppercased()
    }
}
