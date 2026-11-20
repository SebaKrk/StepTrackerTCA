//
//  SubscriptionTier.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

/// What the user's subscription opens.
public enum SubscriptionTier: Equatable, CaseIterable, Identifiable, Sendable {

    /// Recording, and the most recent workouts and plans.
    case basic

    /// Everything.
    case pro

    public var id: Self { self }

    /// Name of the tier as shown to the user.
    public var name: String {
        switch self {
        case .basic:
            return "Basic"
        case .pro:
            return "Pro"
        }
    }
}

extension SubscriptionTier: RawRepresentable {

    // "elite" was a third tier once; a device that stored it keeps full access.
    public init?(rawValue: String) {
        switch rawValue {
        case "basic":
            self = .basic
        case "pro", "elite":
            self = .pro
        default:
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .basic:
            return "basic"
        case .pro:
            return "pro"
        }
    }
}
