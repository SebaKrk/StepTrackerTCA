//
//  WorkoutSortOption.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 14/12/2025.
//

import Foundation
import HealthKit

public enum ActivitiesSortOption: Identifiable, CaseIterable, Equatable, Sendable {
    
    case newestFirst
    case oldestFirst
    case longestFirst
    case shortestFirst
    
    public var id: Self { self }
    
    public var title: String {
        switch self {
        case .newestFirst: return "Newest first"
        case .oldestFirst: return "Oldest first"
        case .longestFirst: return "Longest first"
        case .shortestFirst: return "Shortest first"
        }
    }
    
    public var descriptors: [SortDescriptor<HKWorkout>] {
        switch self {
        case .newestFirst:
            return [SortDescriptor(\HKWorkout.endDate, order: .reverse)]
        case .oldestFirst:
            return [SortDescriptor(\HKWorkout.endDate, order: .forward)]
        case .longestFirst:
            return [SortDescriptor(\HKWorkout.duration, order: .reverse)]
        case .shortestFirst:
            return [SortDescriptor(\HKWorkout.duration, order: .forward)]
        }
    }
    
}
