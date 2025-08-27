//
//  SessionState.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 27/08/2025.
//

import Foundation

enum SessionState {
    
    case countdown
    
    case session
    
    case summary
    
    var title: String {
        switch self {
        case .countdown: return "Countdown"
        case .session: return "Workout Session"
        case .summary: return "Workout Summary"
        }
    }
    
}
