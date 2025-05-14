//
//  WorkoutLocationType.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 14/05/2025.
//

import HealthKit

enum WorkoutLocationType: CaseIterable, Hashable {
    
    case indoor
    case outdoor
    
    var title: String {
        switch self {
        case .indoor:  return "Indoor"
        case .outdoor: return "Outdoor"
        }
    }
    
    var hkType: HKWorkoutSessionLocationType {
        switch self {
        case .indoor:  return .indoor
        case .outdoor: return .outdoor
        }
    }
    
    init?(hkType: HKWorkoutSessionLocationType) {
        switch hkType {
        case .indoor:  self = .indoor
        case .outdoor: self = .outdoor
        default:       return nil
        }
    }
    
}
