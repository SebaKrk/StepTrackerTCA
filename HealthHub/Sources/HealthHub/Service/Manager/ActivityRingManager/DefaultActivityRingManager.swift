//
//  DefaultActivityRingManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 06/06/2025.
//

import HealthKit
import SharedModels

public final class DefaultActivityRingManager: ActivityRingManager {
    
    // MARK: - Properties
    
    let healthStore: HKHealthStore

    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - API
    
    public func fetchTodaySummary() async throws -> ActivityRingData {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: components)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let summary = summaries?.first {
                    let data = ActivityRingData(
                        moveValue: summary.activeEnergyBurned.doubleValue(for: .kilocalorie()),
                        moveGoal: summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie()),
                        exerciseValue: summary.appleExerciseTime.doubleValue(for: .minute()),
                        exerciseGoal: summary.appleExerciseTimeGoal.doubleValue(for: .minute()),
                        standValue: summary.appleStandHours.doubleValue(for: .count()),
                        standGoal: summary.appleStandHoursGoal.doubleValue(for: .count())
                    )
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSError(domain: "NoSummary", code: 0))
                }
            }
            healthStore.execute(query)
        }
    }
    
    public func fetchTodayHourlyData() async throws -> [HourlyActivityData] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        
        var hourlyData: [HourlyActivityData] = []
        
        for hour in 0..<24 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: startOfToday),
                  let hourEnd = calendar.date(byAdding: .hour, value: 1, to: hourStart) else {
                continue
            }
            
            do {
                let activeEnergy = try await fetchActiveEnergy(from: hourStart, to: hourEnd)
                let exerciseMinutes = try await fetchExerciseTime(from: hourStart, to: hourEnd)
                let standHours = try await fetchStandHour(from: hourStart, to: hourEnd)
                
                let data = HourlyActivityData(
                    hour: hour,
                    activeEnergyBurned: activeEnergy,
                    exerciseMinutes: exerciseMinutes,
                    standHours: standHours,
                    date: hourStart
                )
                
                hourlyData.append(data)
            } catch let error as NSError {
                if error.code == 11 {
                    hourlyData.append(HourlyActivityData(
                        hour: hour,
                        activeEnergyBurned: 0,
                        exerciseMinutes: 0,
                        standHours: 0,
                        date: hourStart
                    ))
                } else {
                    hourlyData.append(HourlyActivityData(
                        hour: hour,
                        activeEnergyBurned: 0,
                        exerciseMinutes: 0,
                        standHours: 0,
                        date: hourStart
                    ))
                }
            } catch {
                hourlyData.append(HourlyActivityData(
                    hour: hour,
                    activeEnergyBurned: 0,
                    exerciseMinutes: 0,
                    standHours: 0,
                    date: hourStart
                ))
            }
        }
        
        return hourlyData
    }
    
    // MARK: - Private Methods
    
    private func fetchActiveEnergy(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw NSError(domain: "HealthKitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Active energy type not available"])
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error as NSError? {
                    if error.code == 11 {
                        continuation.resume(returning: 0.0)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let sum = statistics?.sumQuantity() {
                    let value = sum.doubleValue(for: .kilocalorie())
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchExerciseTime(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else {
            throw NSError(domain: "HealthKitError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Exercise time type not available"])
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error as NSError? {
                    if error.code == 11 {
                        continuation.resume(returning: 0.0)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let sum = statistics?.sumQuantity() {
                    let value = sum.doubleValue(for: .minute())
                    continuation.resume(returning: value)
                } else {
                    continuation.resume(returning: 0.0)
                }
            }
            healthStore.execute(query)
        }
    }
    
    private func fetchStandHour(from startDate: Date, to endDate: Date) async throws -> Int {
        guard let standType = HKCategoryType.categoryType(forIdentifier: .appleStandHour) else {
            throw NSError(domain: "HealthKitError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Stand hour type not available"])
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: standType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error as NSError? {
                    if error.code == 11 {
                        continuation.resume(returning: 0)
                    } else {
                        continuation.resume(throwing: error)
                    }
                } else if let categorySamples = samples as? [HKCategorySample] {
                    let stood = categorySamples.contains { $0.value == HKCategoryValueAppleStandHour.stood.rawValue }
                    continuation.resume(returning: stood ? 1 : 0)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }
    
}
