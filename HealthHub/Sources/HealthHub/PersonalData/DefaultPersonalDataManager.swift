//
//  DefaultPersonalDataManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import ComposableArchitecture
import SharedModels
import HealthKit

@preconcurrency
public final class DefaultPersonalDataManager: PersonalDataManager, @unchecked Sendable {
    
    // MARK: - Dependency
    
    @Dependency(\.authorizationManager) var manager
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - API
    
    /// Retrieves user's age by calculating from date of birth stored in HealthKit characteristics.
    public func getAge() async throws -> Int? {
        do {
            let dateOfBirthComponents = try manager.healthStore.dateOfBirthComponents()

            guard let birthDate = Calendar.current.date(from: dateOfBirthComponents) else {
                print("Failed to create date from components")
                return nil
            }

            let calendar = Calendar.current
            return calendar.dateComponents([.year], from: birthDate, to: Date()).year
        } catch {
            print("Failed to fetch age: \(error)")
            return nil
        }
    }

    /// Retrieves user's date of birth directly from HealthKit characteristics.
    public func getBirthDate() async throws -> Date? {
        do {
            let dateOfBirthComponents = try manager.healthStore.dateOfBirthComponents()
            return Calendar.current.date(from: dateOfBirthComponents)
        } catch {
            print("Failed to fetch birth date: \(error)")
            return nil
        }
    }
    
    /// Retrieves user's biological sex directly from HealthKit characteristics as a readable string.
    public func getBiologicalSex() async throws -> BiologicalSex? {
        do {
            let biologicalSex = try manager.healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .male: return .male
            case .female: return .female
            case .other: return .unknown
            case .notSet: return .notSet
            @unknown default: return .unknown
            }
        } catch {
            print("Failed to fetch biological sex: \(error)")
            return nil
        }
    }
    
    // MARK: - Body Metrics API
    
    /// Fetches the most recent height measurement from HealthKit and returns value in centimeters.
    public func getHeight() async throws -> HealthKitData? {
        let heightType = HKQuantityType(.height)
        let samplePredicate = HKSamplePredicate.quantitySample(type: heightType, predicate: nil)
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let results = try await descriptor.result(for: manager.healthStore)
        
        guard let sample = results.first else { return nil }
        
        let heightInCentimeters = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
        return HealthKitData(date: sample.startDate, value: heightInCentimeters)
    }
    
    /// Retrieves average weight from the specified number of days using HealthKitQueryBuilder with discrete averaging.
    public func getWeight(days: Int = 30) async throws -> HealthKitData? {
        let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: days)
        let query = HealthKitQueryBuilder.buildQuery(
            for: .bodyMass,
            startDate: startDate,
            endDate: endDate,
            options: .discreteAverage
        )
        
        let results = try await query.result(for: manager.healthStore)
        let processedData = HealthKitQueryBuilder.processHealthKitData(
            results.statistics(),
            unit: .gramUnit(with: .kilo),
            options: .discreteAverage
        )
        print("📊 Weight result: \(processedData.last?.value ?? -1) kg")
        
        return processedData.last
    }
    
    public func getWeight(for date: Date) async throws -> HealthKitData? {
        let weightType = HKQuantityType(.bodyMass)
        let calendar = Calendar.current
        
        // 1. Szukaj wagi z tego samego dnia
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let sameDayPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let sameDayDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: weightType, predicate: sameDayPredicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let sameDayResults = try await sameDayDescriptor.result(for: manager.healthStore)
        
        if let sample = sameDayResults.first {
            let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            ///print("⚖️ Weight for \(date): \(weight) kg (same day)")
            return HealthKitData(date: sample.startDate, value: weight)
        }
        
        // 2. Fallback - najbliższa waga PRZED tą datą
        let beforePredicate = HKQuery.predicateForSamples(
            withStart: nil,
            end: startOfDay,
            options: .strictEndDate
        )
        
        let fallbackDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: weightType, predicate: beforePredicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let fallbackResults = try await fallbackDescriptor.result(for: manager.healthStore)
        
        if let sample = fallbackResults.first {
            let weight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            ///print("⚖️ Weight for \(date): \(weight) kg (fallback from \(sample.startDate))")
            return HealthKitData(date: sample.startDate, value: weight)
        }
        
        ///print("⚖️ No weight data found for or before \(date)")
        return nil
    }
    
    
    // MARK: - General Heart Rate API
    
    /// Fetches average resting heart rate from the specified days using HealthKitQueryBuilder for cardiovascular data.
    public func getRestingHeartRate(days: Int = 7) async throws -> HealthKitData? {
        let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: days)
        let query = HealthKitQueryBuilder.buildQuery(
            for: .restingHeartRate,
            startDate: startDate,
            endDate: endDate,
            options: .discreteAverage
        )
        
        let results = try await query.result(for: manager.healthStore)
        let processedData = HealthKitQueryBuilder.processHealthKitData(
            results.statistics(),
            unit: .count().unitDivided(by: .minute()),
            options: .discreteAverage
        )
        
        return processedData.first
    }
    
    /// Retrieves resting heart rate for a specific date, with fallback to nearest previous measurement.
    public func getRestingHeartRate(for date: Date) async throws -> HealthKitData? {
        let restingHRType = HKQuantityType(.restingHeartRate)
        let calendar = Calendar.current
        
        // 1. Szukaj RHR z tego samego dnia (okno poranne 00:00 - 11:00)
        let startOfDay = calendar.startOfDay(for: date)
        let morningEnd = calendar.date(byAdding: .hour, value: 11, to: startOfDay)!
        
        let sameDayPredicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: morningEnd,
            options: .strictStartDate
        )
        
        let sameDayDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: restingHRType, predicate: sameDayPredicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let sameDayResults = try await sameDayDescriptor.result(for: manager.healthStore)
        
        if let sample = sameDayResults.first {
            let rhr = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            return HealthKitData(date: sample.startDate, value: rhr)
        }
        
        // 2. Fallback - najbliższe RHR PRZED tą datą
        let beforePredicate = HKQuery.predicateForSamples(
            withStart: nil,
            end: startOfDay,
            options: .strictEndDate
        )
        
        let fallbackDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: restingHRType, predicate: beforePredicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let fallbackResults = try await fallbackDescriptor.result(for: manager.healthStore)
        
        if let sample = fallbackResults.first {
            let rhr = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            return HealthKitData(date: sample.startDate, value: rhr)
        }
        
        return nil
    }
    
    /// Retrieves the user's average heart rate variability from specified time period.
    public func getHeartRateVariability(days: Int = 7) async throws -> HealthKitData? {
        let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: days)
        let query = HealthKitQueryBuilder.buildQuery(
            for: .heartRateVariabilitySDNN,
            startDate: startDate,
            endDate: endDate,
            options: .discreteAverage
        )
        
        let results = try await query.result(for: manager.healthStore)
        let processedData = HealthKitQueryBuilder.processHealthKitData(
            results.statistics(),
            unit: .secondUnit(with: .milli),
            options: .discreteAverage
        )
        
        return processedData.first
    }
    
    // MARK: - General Activity API
    
    /// Retrieves the user's active energy burned from specified time period.
    public func getActiveEnergyBurned(days: Int = 1) async throws -> HealthKitData? {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: days)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        var interval = DateComponents()
        interval.day = 1
        
        let query = HKStatisticsCollectionQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { query, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: nil)
                    return
                }
                
                var dailyValues: [Double] = []
                
                results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let value = sum.doubleValue(for: .kilocalorie())
                        if value > 0 {
                            dailyValues.append(value)
                        }
                    }
                }
                
                guard !dailyValues.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let average = dailyValues.reduce(0, +) / Double(dailyValues.count)
                let result = HealthKitData(date: endDate, value: average)
                continuation.resume(returning: result)
            }
            
            manager.healthStore.execute(query)
        }
    }
    
    // MARK: - Training Readiness Specific API
    
    /// Retrieves this morning's resting heart rate measurement.
    ///
    /// Fetches RHR from the extended morning window (midnight - 11 AM today) to capture
    /// measurements taken during sleep and early morning. Apple Watch typically records
    /// RHR during sleep periods.
    ///
    /// - Returns: A `HealthKitData` object containing RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getThisMorningRestingHeartRate() async throws -> HealthKitData? {
        
        let window = TrainingReadinessTimeWindows.thisMorningRHRWindow()
        
        // print("🔍 RHR Debug: Searching window \(window.start) to \(window.end)")
        
        let restingHeartRateType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: window.start,
            end: window.end,
            options: .strictStartDate
        )
        
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: restingHeartRateType,
            predicate: predicate
        )
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)],
            limit: 1
        )
        
        let results = try await descriptor.result(for: manager.healthStore)
        
        // print("🔍 RHR Debug: Found \(results.count) samples")
        
        guard let sample = results.first else {
            return nil
        }
        
        let rhrValue = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
        // Apple Watch records RHR with startDate at midnight, but endDate contains actual measurement time
        return HealthKitData(date: sample.endDate, value: rhrValue)
    }
    
    /// Retrieves average morning resting heart rate from specified number of days.
    ///
    /// Fetches RHR measurements from the extended morning window (midnight - 11 AM) for
    /// each of the specified days and calculates their average.
    ///
    /// - Parameter days: Number of days to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average morning RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageMorningRestingHeartRate(days: Int = 7) async throws -> HealthKitData? {
        
        let restingHeartRateType = HKQuantityType(.restingHeartRate)
        var allValues: [Double] = []
        
        for dayOffset in 0..<days {
            let calendar = Calendar.current
            let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            // Window: midnight to 11 AM for each day
            let windowStart = calendar.startOfDay(for: targetDate)
            let windowEnd = calendar.date(byAdding: .hour, value: 11, to: windowStart)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: windowStart,
                end: windowEnd,
                options: .strictStartDate
            )
            
            let samplePredicate = HKSamplePredicate.quantitySample(
                type: restingHeartRateType,
                predicate: predicate
            )
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [samplePredicate],
                sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .forward)],
                limit: 1
            )
            
            let results = try await descriptor.result(for: manager.healthStore)
            
            if let sample = results.first {
                let value = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                allValues.append(value)
            }
        }
        
        guard !allValues.isEmpty else { return nil }
        
        let average = allValues.reduce(0, +) / Double(allValues.count)
        return HealthKitData(date: Date(), value: average)
    }
    
    /// Retrieves last night's HRV measurement.
    ///
    /// Fetches HRV from last night's sleep window (8 PM yesterday - 10 AM today).
    ///
    /// - Returns: A `HealthKitData` object containing HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getLastNightHRV() async throws -> HealthKitData? {
        let window = TrainingReadinessTimeWindows.lastNightHRVWindow()
        
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(
            withStart: window.start,
            end: window.end,
            options: .strictStartDate
        )
        
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: hrvType,
            predicate: predicate
        )
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)]
        )
        
        let results = try await descriptor.result(for: manager.healthStore)
        
        guard !results.isEmpty else { return nil }
        
        // Find the most recent sample for timestamp (endDate = actual measurement time)
        let mostRecentSample = results.first!
        
        let totalHRV = results.reduce(0.0) { sum, sample in
            sum + sample.quantity.doubleValue(for: .secondUnit(with: .milli))
        }
        
        let averageHRV = totalHRV / Double(results.count)
        // Use endDate for actual measurement time (same as RHR fix)
        return HealthKitData(date: mostRecentSample.endDate, value: averageHRV)
    }
    
    /// Retrieves average nightly HRV from specified number of nights.
    ///
    /// - Parameter nights: Number of nights to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageNightlyHRV(nights: Int = 7) async throws -> HealthKitData? {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        var allValues: [Double] = []
        
        for dayOffset in 0..<nights {
            let calendar = Calendar.current
            let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            let windowEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: targetDate)!
            let windowStart = calendar.date(byAdding: .hour, value: -14, to: windowEnd)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: windowStart,
                end: windowEnd,
                options: .strictStartDate
            )
            
            let samplePredicate = HKSamplePredicate.quantitySample(
                type: hrvType,
                predicate: predicate
            )
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [samplePredicate],
                sortDescriptors: []
            )
            
            let results = try await descriptor.result(for: manager.healthStore)
            
            if !results.isEmpty {
                let nightAverage = results.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                } / Double(results.count)
                
                allValues.append(nightAverage)
            }
        }
        
        guard !allValues.isEmpty else { return nil }
        
        let average = allValues.reduce(0, +) / Double(allValues.count)
        return HealthKitData(date: Date(), value: average)
    }
    
    /// Retrieves yesterday's total active energy burned.
    ///
    /// Fetches activity from full previous day (00:00 - 23:59 yesterday).
    /// Note: HealthKit's activeEnergyBurned already includes workout energy,
    /// so we only need to query quantity samples - no need to add workout energy separately.
    ///
    /// - Returns: A `HealthKitData` object containing total active energy in kilocalories,
    ///           or `nil` if no activity data is available for yesterday
    /// - Throws: HealthKit errors if data access fails or permissions are not granted
//    public func getYesterdayActiveEnergy() async throws -> HealthKitData? {
//        let window = TrainingReadinessTimeWindows.yesterdayFullDay()
//        let healthStore = manager.healthStore
//
//        let query = HealthKitQueryBuilder.buildQuery(
//            for: .activeEnergyBurned,
//            startDate: window.start,
//            endDate: window.end,
//            options: .cumulativeSum
//        )
//
//        let results = try await query.result(for: healthStore)
//
//        let processedData = HealthKitQueryBuilder.processHealthKitData(
//            results.statistics(),
//            unit: .kilocalorie(),
//            options: .cumulativeSum
//        )
//
//        let totalEnergy = processedData.last?.value ?? 0
//
//        let workouts = try await HealthKitQueryBuilder.fetchWorkouts(
//            from: window.start,
//            to: window.end,
//            healthStore: healthStore
//        )
//
//        let energyType = HKQuantityType(.activeEnergyBurned)
//        let workoutEnergy = workouts.reduce(0.0) { total, workout in
//            if let statistics = workout.statistics(for: energyType),
//               let sum = statistics.sumQuantity() {
//                return total + sum.doubleValue(for: HKUnit.kilocalorie())
//            }
//            return total
//        }
//
//        let backgroundEnergy = totalEnergy - workoutEnergy
//
//        // MARK: - 🔍 DEBUG
//        print("🏃 Activity window: \(window.start) → \(window.end)")
//        print("🏃 Workout energy: \(String(format: "%.0f", workoutEnergy)) kcal (\(workouts.count) workouts)")
//        print("🏃 Background energy: \(String(format: "%.0f", backgroundEnergy)) kcal")
//        print("🏃 Total energy: \(String(format: "%.0f", totalEnergy)) kcal")
//        print("═══════════════════════════════════════════════════")
//
//        guard totalEnergy > 0 else {
//            return nil
//        }
//
//        return HealthKitData(date: window.end, value: totalEnergy)
//    }

    /// Retrieves active energy for a specific day using workout + fallback logic.
    ///
    /// This method implements a two-tier approach:
    /// 1. First tries to get energy from workouts (Apple Watch recorded exercises)
    /// 2. Falls back to total active energy if no workouts found
    ///
    /// - Parameters:
    ///   - dayStart: Start of the day (00:00:00)
    ///   - dayEnd: End of the day (00:00:00 next day)
    /// - Returns: Energy in kcal, or nil if no data available
    /// - Throws: HealthKit errors if data access fails
    private func getActiveEnergyForDay(
        dayStart: Date,
        dayEnd: Date
    ) async throws -> Double? {
        let healthStore = manager.healthStore
        let energyType = HKQuantityType(.activeEnergyBurned)
        
        // 1️⃣ First: Check for workouts
        let workouts = try await HealthKitQueryBuilder.fetchWorkouts(
            from: dayStart,
            to: dayEnd,
            healthStore: healthStore
        )
        
        let workoutEnergy = workouts.reduce(0.0) { total, workout in
            guard
                let statistics = workout.statistics(for: energyType),
                let sum = statistics.sumQuantity()
            else {
                return total
            }
            return total + sum.doubleValue(for: .kilocalorie())
        }
        
        if workoutEnergy > 0 {
            return workoutEnergy  // Return workout energy if available
        }
        
        // 2️⃣ Fallback: Total active energy
        let predicate = HKQuery.predicateForSamples(
            withStart: dayStart,
            end: dayEnd,
            options: .strictStartDate
        )
        
        let statistics = try await withCheckedThrowingContinuation { 
            (continuation: CheckedContinuation<HKStatistics?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { (query: HKStatisticsQuery, statistics: HKStatistics?, error: Error?) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: statistics)
                }
            }
            healthStore.execute(query)
        }
        
        if let sum = statistics?.sumQuantity() {
            let value = sum.doubleValue(for: .kilocalorie())
            return value > 0 ? value : nil
        }
        
        return nil
    }
    
    public func getYesterdayActiveEnergy() async throws -> HealthKitData? {
        let window = TrainingReadinessTimeWindows.yesterdayFullDay()
        
        guard let energy = try await getActiveEnergyForDay(
            dayStart: window.start,
            dayEnd: window.end
        ) else {
            return nil
        }
        
        return HealthKitData(date: window.start, value: energy)
    }
    
    /// Retrieves average daily active energy from specified number of days.
    ///
    /// - Parameter days: Number of days to average (default: 7)
    /// - Returns: A `HealthKitData` object containing average daily energy in kcal, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageDailyActiveEnergy(days: Int = 7) async throws -> HealthKitData? {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let ranges = TrainingReadinessTimeWindows.lastFullDays(count: days)
        
        var dailyValues: [Double] = []
        
        for range in ranges {
            let predicate = HKQuery.predicateForSamples(
                withStart: range.start,
                end: range.end,
                options: .strictStartDate
            )
            
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: energyType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { (query: HKStatisticsQuery, statistics: HKStatistics?, error: Error?) in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: statistics)
                    }
                }
                
                manager.healthStore.execute(query)
            }
            
            if let sum = statistics?.sumQuantity() {
                let value = sum.doubleValue(for: HKUnit.kilocalorie())
                if value > 0 {
                    dailyValues.append(value)
                }
            }
        }
        
        guard !dailyValues.isEmpty else { return nil }
        
        let average = dailyValues.reduce(0, +) / Double(dailyValues.count)
        return HealthKitData(date: Date(), value: average)
    }
    
    /// DEBUG: Lista wszystkie pomiary RHR z ostatnich 7 dni
    public func debugListAllRHR() async throws {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        
        let restingHeartRateType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: sevenDaysAgo,
            end: now,
            options: .strictStartDate
        )
        
        let samplePredicate = HKSamplePredicate.quantitySample(
            type: restingHeartRateType,
            predicate: predicate
        )
        
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)]
        )
        
        let results = try await descriptor.result(for: manager.healthStore)
        
        // print("📋 RHR Debug: Found \(results.count) total RHR samples in last 7 days")
        // print("📋 Time range: \(sevenDaysAgo) to \(now)")
        // print("📋 Samples:")
        
        for (index, sample) in results.enumerated() {
            let value = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: sample.startDate)
            
            // print("  [\(index + 1)] \(dateString) - RHR: \(value) bpm")
        }
        
        if results.isEmpty {
            print("❌ No RHR data found at all in last 7 days!")
        }
    }
    
    // MARK: - Historical Data Per-Day Implementation
    
    public func getRestingHeartRateHistory(days: Int) async throws -> [HealthKitData?] {
        var results: [HealthKitData?] = []
        let calendar = Calendar.current
        
        for daysAgo in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                results.append(nil)
                continue
            }
            
            let data = try await getRestingHeartRate(for: date)
            results.append(data)
        }
        
        return results.reversed()
    }
    
    public func getHeartRateVariabilityHistory(nights: Int) async throws -> [HealthKitData?] {
        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        var results: [HealthKitData?] = []
        let calendar = Calendar.current
        
        for nightsAgo in 0..<nights {
            guard let targetDate = calendar.date(byAdding: .day, value: -nightsAgo, to: Date()) else {
                results.append(nil)
                continue
            }
            
            // Okno per-night: 8 PM wczoraj → 10 AM dzisiaj (ta sama logika co getLastNightHRV)
            let windowEnd = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: targetDate)!
            let windowStart = calendar.date(byAdding: .hour, value: -14, to: windowEnd)!
            
            let predicate = HKQuery.predicateForSamples(
                withStart: windowStart,
                end: windowEnd,
                options: .strictStartDate
            )
            
            let samplePredicate = HKSamplePredicate.quantitySample(
                type: hrvType,
                predicate: predicate
            )
            
            let descriptor = HKSampleQueryDescriptor(
                predicates: [samplePredicate],
                sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .reverse)]
            )
            
            let samples = try await descriptor.result(for: manager.healthStore)
            
            if !samples.isEmpty {
                let totalHRV = samples.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                }
                let averageHRV = totalHRV / Double(samples.count)
                results.append(HealthKitData(date: windowStart, value: averageHRV))
            } else {
                results.append(nil)
            }
        }
        
        return results.reversed()
    }
    
    public func getActiveEnergyBurnedHistory(days: Int) async throws -> [HealthKitData?] {
        let calendar = Calendar.current
        let now = Date()

        // Exclude today (incomplete data) — anchor on yesterday's startOfDay as range end.
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let startDate = calendar.date(byAdding: .day, value: -days, to: now) else {
            return []
        }
        let anchorDate = calendar.startOfDay(for: startDate)
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: yesterday))!

        let energyType = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(
            withStart: anchorDate,
            end: endDate,
            options: .strictStartDate
        )

        let query = HKStatisticsCollectionQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: DateComponents(day: 1)
        )

        let healthStore = manager.healthStore

        return try await withCheckedThrowingContinuation { continuation in
            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [HealthKitData?] = []
                collection.enumerateStatistics(from: anchorDate, to: endDate) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        let kcal = sum.doubleValue(for: .kilocalorie())
                        results.append(HealthKitData(date: stats.startDate, value: kcal))
                    } else {
                        results.append(nil)
                    }
                }
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }
    
}
