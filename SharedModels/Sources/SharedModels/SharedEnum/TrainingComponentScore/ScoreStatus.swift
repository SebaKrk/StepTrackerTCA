//
//  ScoreStatus.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 26/10/2025.
//

import SwiftUI

/// How a single component moves today's readiness.
///
/// Describes the component's **effect**, not the quality of its value. "Below
/// average" cannot work for both resting heart rate and HRV — lower is better
/// for one and worse for the other — and it also reads as a comment on the
/// measurement rather than on the score derived from it.
///
/// The neutral case exists because a component sitting exactly on its baseline
/// is the most common outcome, and the previous quartile split had no room for
/// it: zero landed in the second quartile and was presented as a warning.
public enum ScoreStatus: Sendable, Equatable {

    /// Takes a large bite out of today's readiness.
    case stronglyLowers

    /// Pulls today's readiness down.
    case lowers

    /// Sits on the baseline and changes nothing.
    case neutral

    /// Pushes today's readiness up.
    case raises

    /// Adds as much as this component can.
    case stronglyRaises

    // MARK: - Display Properties

    /// Display text for the status.
    ///
    /// Deliberately short — the tiles are half the screen wide and the word
    /// "readiness" already sits in the card heading above them.
    public var text: String {
        switch self {
        case .stronglyLowers:
            return String(localized: "Strongly lowers", bundle: .module)
        case .lowers:
            return String(localized: "Lowers", bundle: .module)
        case .neutral:
            return String(localized: "No effect", bundle: .module)
        case .raises:
            return String(localized: "Raises", bundle: .module)
        case .stronglyRaises:
            return String(localized: "Strongly raises", bundle: .module)
        }
    }

    /// SF Symbol icon name for the status.
    public var icon: String {
        switch self {
        case .stronglyLowers: return "arrow.down.circle.fill"
        case .lowers: return "arrow.down.circle"
        case .neutral: return "equal.circle"
        case .raises: return "arrow.up.circle"
        case .stronglyRaises: return "arrow.up.circle.fill"
        }
    }

    /// Color associated with the status.
    public var color: Color {
        switch self {
        case .stronglyLowers: return .red
        case .lowers: return .orange
        case .neutral: return .secondary
        case .raises: return .mint
        case .stronglyRaises: return .green
        }
    }

}
