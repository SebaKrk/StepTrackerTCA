//
//  TeamSegment.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Ściuba on 25/10/2026.
//

import Foundation

/// Top switch of the Team tab.
enum TeamSegment: CaseIterable, Identifiable, Equatable {

    /// Groups the user belongs to, joined by invite.
    case `private`

    /// Discoverable groups — not available yet.
    case `public`

    var id: Self { self }

    var title: String {
        switch self {
        case .private:
            return String(localized: "Private", bundle: .main)
        case .public:
            return String(localized: "Public", bundle: .main)
        }
    }
}
