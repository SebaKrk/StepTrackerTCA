//
//  WatchConnectivityStatus.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import WatchConnectivity

/// Status połączenia z Apple Watch
public enum WatchConnectivityStatus: String, CaseIterable, Sendable {
    case unknown = "unknown"
    case notSupported = "not supported"
    case notPaired = "not paired"
    case appNotInstalled = "app not installed"
    case ready = "connect"
    case unreachable = "unreax  chable"
}
