//
//  SubscriptionTier+Access.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 19/11/2026.
//

import Foundation

/// The one table of what each tier opens.
extension SubscriptionTier {

    /// Whether Basic is limited at all.
    ///
    /// Off in shipped builds until Pro can really be bought: a limit nobody can lift
    /// would only lock people out. Debug builds keep it on so the locks stay testable.
    public static var enforcesLimits: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// Whether this tier opens a feature sold with Pro.
    public func opens(_ feature: ProFeature) -> Bool {
        !Self.enforcesLimits || self == .pro
    }

    /// How many of the most recent workouts or plans this tier opens; `nil` opens all.
    public var openRecentItemCount: Int? {
        guard Self.enforcesLimits else { return nil }
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
