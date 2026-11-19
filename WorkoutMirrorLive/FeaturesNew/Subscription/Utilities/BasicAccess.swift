//
//  BasicAccess.swift
//  MyFitnessJournal
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// What the Basic tier opens in a list of the user's own records.
enum BasicAccess {

    /// How many of the most recent workouts or plans stay open.
    static let openItemCount = 3

    /// Identifiers of the most recent items, the only ones Basic opens.
    static func openIDs<ID: Hashable>(mostRecentOf items: [(id: ID, date: Date)]) -> Set<ID> {
        Set(
            items
                .sorted { $0.date > $1.date }
                .prefix(openItemCount)
                .map(\.id)
        )
    }
}
