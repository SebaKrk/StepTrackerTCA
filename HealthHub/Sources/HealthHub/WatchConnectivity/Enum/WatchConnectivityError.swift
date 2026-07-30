//
//  WatchConnectivityError.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import Foundation

/// Błędy WatchConnectivity
public enum WatchConnectivityError: Error, Sendable {
    case notSupported
    case notPaired
    case sessionNotActivated
}
