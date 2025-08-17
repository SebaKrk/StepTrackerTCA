////
////  WorkoutType.swift
////  MyFitnessJournal
////
////  Created by Sebastian Sciuba on 04/08/2025.
////
//
//import HealthKit
//
//public enum WorkoutType: CaseIterable, Codable, Hashable, Identifiable {
//    
//    case functional
//    case cross
//    case boxing
//    
//    public var id: Self { self }
//    
//    public var title: String {
//        switch self {
//        case .functional:       return "Functional"
//        case .cross:            return "Cross"
//        case .boxing:           return "Boxing"
//        }
//    }
//    
//    public var iconName: String {
//        switch self {
//        case .functional:       return "figure.strengthtraining.functional"
//        case .cross:            return "figure.cross.training"
//        case .boxing:           return "figure.boxing"
//        }
//    }
//    
//    /// Map to HealthKit equivalent
//    public var hkType: HKWorkoutActivityType {
//        switch self {
//        case .functional:       return .functionalStrengthTraining
//        case .cross:            return .crossTraining
//        case .boxing:           return .boxing
//        }
//    }
//    
//    /// Create from HealthKit value
//    public init?(hkType: HKWorkoutActivityType) {
//        switch hkType {
//        case .functionalStrengthTraining:  self = .functional
//        case .crossTraining:               self = .cross
//        case .boxing:                      self = .boxing
//        default:                           return nil
//        }
//    }
//    
//}
