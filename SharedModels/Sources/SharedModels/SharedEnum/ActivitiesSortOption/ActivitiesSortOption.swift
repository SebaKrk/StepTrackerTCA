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
        case .newestFirst:
            return String(localized: "Newest first", bundle: .module)
        case .oldestFirst:
            return String(localized: "Oldest first", bundle: .module)
        case .longestFirst:
            return String(localized: "Longest first", bundle: .module)
        case .shortestFirst:
            return String(localized: "Shortest first", bundle: .module)
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
