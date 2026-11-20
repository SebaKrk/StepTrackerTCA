//
//  SubscriptionTier+Access.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// The one table of what each tier opens.
extension SubscriptionTier {

    /// Whether this tier opens a feature sold with Pro.
    public func opens(_ feature: ProFeature) -> Bool {
        self == .pro
    }

    /// How many of the most recent workouts or plans this tier opens; `nil` opens all.
    public var openRecentItemCount: Int? {
        switch self {
        case .basic:
            return 3
        case .pro:
            return nil
        }
    }

    /// Identifiers this tier opens among dated items: the most recent few, or every one.
    public func openIDs<ID: Hashable>(mostRecentOf items: [(id: ID, date: Date)]) -> Set<ID> {
        guard let count = openRecentItemCount else {
            return Set(items.map(\.id))
        }
        return Set(
            items
                .sorted { $0.date > $1.date }
                .prefix(count)
                .map(\.id)
        )
    }
}
