//
//  SimpleWorkoutGoal.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 12/07/2025.
//

import Foundation

enum SimpleWorkoutGoal: CaseIterable, Hashable {
    
    case open
    case timeLimit

    var title: String {
        switch self {
        case .open: return "Open"
        case .timeLimit: return "Time Limit"
        }
    }
    
}
