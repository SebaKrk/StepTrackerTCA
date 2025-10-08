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
    
    /// Retrieves total sleep duration from last night.
    ///
    /// Fetches sleep data from the pragmatic window spanning yesterday evening (8 PM)
    /// to this morning (10 AM). This captures the primary sleep session regardless of
    /// exact start/end times or brief awakenings.
    ///
    /// - Returns: A `HealthKitData` object containing sleep duration in hours, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getLastNightSleep() async throws -> HealthKitData? {
        let window = TrainingReadinessTimeWindows.lastNightSleepWindow()
        
        let sleepType = HKCategoryType(.sleepAnalysis)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: window.start,
            end: window.end,
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
        
        // Filter for actual sleep stages (exclude awake and in bed)
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
        
        // Calculate total sleep time in seconds
        let totalSleepSeconds = sleepSamples.reduce(0.0) { total, sample in
            total + sample.endDate.timeIntervalSince(sample.startDate)
        }
        
        // Convert to hours
        let totalSleepHours = totalSleepSeconds / 3600.0
        
        guard totalSleepHours > 0 else { return nil }
        
        return HealthKitData(
            date: window.end,
            value: totalSleepHours
        )
    }
    
    /// Retrieves average sleep duration from specified number of nights.
    ///
    /// Calculates the mean sleep duration by fetching data from multiple nights using
    /// the same pragmatic time window (8 PM → 10 AM) for each night.
    ///
    /// - Parameter nights: Number of nights to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average sleep in hours, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageSleepFromLastNights(nights: Int = 7) async throws -> HealthKitData? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        var nightlyValues: [Double] = []
        
        // Iterate through each night
        for dayOffset in 0..<nights {
            let calendar = Calendar.current
            let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            // Create window for this specific night: 8 PM yesterday → 10 AM today
            let windowEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: targetDate)!
            let windowStart = calendar.date(byAdding: .hour, value: -14, to: windowEnd)! // 14 hours back = 8 PM previous day
            
            let predicate = HKQuery.predicateForSamples(
                withStart: windowStart,
                end: windowEnd,
                options: .strictStartDate
            )
            
            let samplePredicate = HKSamplePredicate.categorySample(
                type: sleepType,
                predicate: predicate
            )
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [samplePredicate],
                sortDescriptors: []
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
            
            // Calculate sleep for this night
            if !sleepSamples.isEmpty {
                let nightSleepSeconds = sleepSamples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                
                let nightSleepHours = nightSleepSeconds / 3600.0
                
                if nightSleepHours > 0 {
                    nightlyValues.append(nightSleepHours)
                }
            }
        }
        
        // Calculate average
        guard !nightlyValues.isEmpty else { return nil }
        
        let average = nightlyValues.reduce(0, +) / Double(nightlyValues.count)
        
        return HealthKitData(
            date: Date(),
            value: average
        )
    }
}
