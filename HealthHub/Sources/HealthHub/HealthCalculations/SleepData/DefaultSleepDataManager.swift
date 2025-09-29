//
//  DefaultSleepDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import ComposableArchitecture
import Foundation
import HealthKit
import SharedModels

@preconcurrency
public final class DefaultSleepDataManager: SleepDataManager, @unchecked Sendable {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var manager
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - API
    
    /// Retrieves total sleep duration from specified time period.
    ///
    /// Fetches sleep analysis data from HealthKit and calculates total sleep time
    /// by summing all sleep stages (asleep, in bed, core, deep, REM).
    ///
    /// - Parameter days: Number of days to look back (default: 1 for last night)
    /// - Returns: A `HealthKitData` object containing sleep duration in hours,
    ///           or `nil` if no sleep data is available
    /// - Throws: HealthKit errors if data access fails
    public func getSleepDuration(days: Int = 1) async throws -> HealthKitData? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: days)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let samplePredicate = HKSamplePredicate.categorySample(
            type: sleepType,
            predicate: predicate
        )
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKCategorySample.startDate, order: .reverse)]
        )
        
        let samples = try await descriptor.result(for: manager.healthStore)
        
        // Filter for actual sleep stages
        let sleepSamples = samples.filter { sample in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else {
                return false
            }
            
            switch value {
            case .asleepCore, .asleepDeep, .asleepREM, .asleepUnspecified, .asleep:
                return true
            case .awake, .inBed:
                return false
            @unknown default:
                return false
            }
        }
        
        let totalSleepSeconds = sleepSamples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        
        let totalSleepHours = totalSleepSeconds / 3600.0
        
        guard totalSleepHours > 0 else { return nil }
        
        let averageSleepHours = days > 1 ? totalSleepHours / Double(days) : totalSleepHours
        
        return HealthKitData(
            date: endDate,
            value: averageSleepHours 
        )
    }
}
