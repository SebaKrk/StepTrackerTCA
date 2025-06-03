//
//  WorkoutOptionAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import Foundation

enum WorkoutOptionAW: Codable, Hashable, Identifiable, CaseIterable {
    
    /// A workout that has been scheduled in advance, typically at a specific time or date.
    case scheduled
    
    /// A workout mirrored from another device or session, such as an iPhone or a coach-led session.
    case mirroring
    
    /// A planned workout based on a predefined structure or training plan.
    case planned
    
    /// A free-form workout without any predefined plan or structure.
    case free

    var id: Self { self }
    
    /// A human-readable title representing the workout option.
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
