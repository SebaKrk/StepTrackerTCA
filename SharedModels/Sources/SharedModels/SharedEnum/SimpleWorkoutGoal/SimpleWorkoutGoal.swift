//
//  SimpleWorkoutGoal.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/07/2025.
//

import Foundation

public enum SimpleWorkoutGoal: String, CaseIterable, Hashable, Codable, Sendable {

    case open
    case timeLimit

    public var title: String {
        switch self {
        case .open: return "Open"
        case .timeLimit: return "Time Limit"
        }
    }
    
}
