//
//  WorkoutOptionAW.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 19/05/2025.
//

import Foundation

public enum WorkoutOptionAW: Codable, Hashable, Identifiable, CaseIterable {
    
    /// A workout that has been scheduled in advance, typically at a specific time or date.
    case scheduled
    
    /// A workout mirrored from another device or session, such as an iPhone or a coach-led session.
    case mirroring
    
    /// A planned workout based on a predefined structure or training plan.
    case planned
    
    /// A free-form workout without any predefined plan or structure.
    case free

    public var id: Self { self }
    
    /// A human-readable title representing the workout option.
    public var title: String {
        switch self {
        case .scheduled:
            return String(localized: "Scheduled", bundle: .module)
        case .mirroring:
            return String(localized: "Mirroring", bundle: .module)
        case .planned:
            return String(localized: "Planned", bundle: .module)
        case .free:
            return String(localized: "Free", bundle: .module)
        }
    }
    
}
