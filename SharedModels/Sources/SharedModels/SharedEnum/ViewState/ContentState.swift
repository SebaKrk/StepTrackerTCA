//
//  ContentState.swift
//  SharedModels
//
//  Created by Sebastian Sciuba on 01/10/2025.
//

import Foundation

public enum ContentState: Equatable {

    case loading

    case unauthorized

    case noData

    case ready(SubscriptionTier)

    /// Convenience flag for views that only need to know whether the state is `.ready`,
    /// without caring about the associated `SubscriptionTier`.
    public var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}
