//
//  SetUnit.swift
//  SharedModels
//
//  Created by Sebastian Ściuba on 29/10/2026.
//

import Foundation

/// What a planned set counts: "5 reps", "30 seconds", "200 m", "15 cal".
public enum SetUnit: String, Codable, Sendable, CaseIterable {
    case reps
    case seconds
    case meters
    case calories
}
