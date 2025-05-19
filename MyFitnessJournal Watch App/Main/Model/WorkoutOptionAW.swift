//
//  WorkoutOptionAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import Foundation

enum WorkoutOptionAW: Codable, Hashable, Identifiable, CaseIterable {
    
    ///
    case scheduled
    
    ///
    case mirroring
    
    ///
    case planned
    
    ///
    case free

    var id: Self { self }
    
    var title: String {
        switch self {
        case .scheduled:
            return "Scheduled"
        case .mirroring:
            return "Mirroring"
        case .planned:
            return "Planned"
        case .free:
            return "Free"
        }
    }
    
}
