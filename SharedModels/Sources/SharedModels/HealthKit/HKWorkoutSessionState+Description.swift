//
//  HKWorkoutSessionState+Description.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 22/05/2026.
//

import HealthKit

extension HKWorkoutSessionState {
    /// Human-readable name for diagnostic logs.
    /// Apple doesn't provide one — `rawValue` is just 0-5 which is hard to read in log dumps.
    public var description: String {
        switch self {
        case .notStarted: return "notStarted"
        case .running: return "running"
        case .paused: return "paused"
        case .prepared: return "prepared"
        case .stopped: return "stopped"
        case .ended: return "ended"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}
