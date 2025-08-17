//
//  WorkoutSessionState.swift
//  WorkoutMirrorLive
//
//  Created by Sebastian Sciuba on 05/08/2025.
//

import Foundation

enum WorkoutSessionState {
    
    case start
    
    case countdown
    
    case session
    
    case summary
    
    var title: String {
        switch self {
        case .start: return "Start"
        case .countdown: return "Countdown"
        case .session: return "Workout Session"
        case .summary: return "Workout Summary"
        }
    }
}
