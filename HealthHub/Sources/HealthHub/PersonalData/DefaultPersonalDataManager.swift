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
                #if DEBUG
                print("Failed to create date from components")
                #endif
                return nil
            }

            let calendar = Calendar.current
            return calendar.dateComponents([.year], from: birthDate, to: Date()).year
        } catch {
            #if DEBUG
            print("Failed to fetch age: \(error)")
            #endif
            return nil
        }
    }

    /// Retrieves user's date of birth directly from HealthKit characteristics.
    public func getBirthDate() async throws -> Date? {
        do {
            let dateOfBirthComponents = try manager.healthStore.dateOfBirthComponents()
            return Calendar.current.date(from: dateOfBirthComponents)
        } catch {
            #if DEBUG
            print("Failed to fetch birth date: \(error)")
            #endif
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
            #if DEBUG
            print("Failed to fetch biological sex: \(error)")
            #endif
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
        #if DEBUG
        print("📊 Weight result: \(processedData.last?.value ?? -1) kg")
        #endif
        
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
    
    /// Retrieves the resting heart rate recorded within a window.
    ///
    /// Takes the most recent reading in the range. Callers pass the window, so
    /// nothing here assumes a clock hour.
    ///
    /// - Parameter window: Range to read the measurement from
    /// - Returns: A `HealthKitData` object containing RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getRestingHeartRate(in window: ClosedRange<Date>) async throws -> HealthKitData? {

        let restingHeartRateType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(
            withStart: window.lowerBound,
            end: window.upperBound,
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
    
    /// Retrieves average resting heart rate across the given windows.
    ///
    /// - Parameter windows: One range per day to average over
    /// - Returns: A `HealthKitData` object containing average RHR in bpm, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageRestingHeartRate(
        in windows: [ClosedRange<Date>],
        takingFirst count: Int
    ) async throws -> HealthKitData? {

        // One query spanning every window, then grouped in memory. Seven windows
        // used to mean seven round trips to HealthKit for a single baseline.
        let samples = try await quantitySamples(
            of: HKQuantityType(.restingHeartRate),
            covering: windows
        )

        let unit = HKUnit.count().unitDivided(by: .minute())

        // `last`, not `first`: the samples are oldest-first and the measured value
        // takes the newest reading of its day. Picking the oldest here compared two
        // different quantities whenever a second source also writes this type.
        let allValues: [Double] = windows.compactMap { window in
            samples
                .last { window.contains($0.startDate) }
                .map { $0.quantity.doubleValue(for: unit) }
        }

        // Newest first, so this keeps the most recent days that have a reading
        // and treats the rest of the pool as a reserve for gaps.
        let used = Array(allValues.prefix(max(count, 1)))

        guard !used.isEmpty else { return nil }

        let average = used.reduce(0, +) / Double(used.count)
        return HealthKitData(date: windows.first?.upperBound ?? Date(), value: average)
    }

    /// Sums active energy per calendar day across the span the windows cover.
    ///
    /// HealthKit does the bucketing, so overlapping and out-of-order samples are
    /// apportioned the same way the Health app reports them.
    ///
    /// - Parameter windows: Windows the caller will group the result by
    /// - Returns: Day start to total kilocalories, for days that burned anything
    private func dailyActiveEnergyTotals(
        covering windows: [ClosedRange<Date>]
    ) async throws -> [Date: Double] {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return [:]
        }

        let healthStore = manager.healthStore
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let collection: HKStatisticsCollection? = try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<HKStatisticsCollection?, Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: HKQuantityType(.activeEnergyBurned),
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchor,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results)
                }
            }

            healthStore.execute(query)
        }

        guard let collection else { return [:] }

        var totals: [Date: Double] = [:]

        collection.enumerateStatistics(from: anchor, to: end) { statistics, _ in
            guard let sum = statistics.sumQuantity() else { return }

            totals[calendar.startOfDay(for: statistics.startDate)] =
                sum.doubleValue(for: .kilocalorie())
        }

        return totals
    }

    public func heartRateCoverage(in window: ClosedRange<Date>) async throws -> ClosedRange<Date>? {
        let samples = try await quantitySamples(
            of: HKQuantityType(.heartRate),
            covering: [window]
        )

        guard let first = samples.first?.startDate,
              let last = samples.last?.endDate,
              last > first else {
            return nil
        }

        return first...last
    }

    /// Reads every sample of a type across the span the windows cover.
    ///
    /// Returns them sorted by start date so callers can slice per window without
    /// issuing one query per window.
    ///
    /// - Parameters:
    ///   - type: Quantity type to read
    ///   - windows: Windows the caller will group the result by
    /// - Returns: Samples within the overall span, oldest first
    private func quantitySamples(
        of type: HKQuantityType,
        covering windows: [ClosedRange<Date>]
    ) async throws -> [HKQuantitySample] {
        guard let start = windows.map(\.lowerBound).min(),
              let end = windows.map(\.upperBound).max() else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .forward)]
        )

        return try await descriptor.result(for: manager.healthStore)
    }
    
    /// Retrieves average heart rate variability within a window.
    ///
    /// - Parameter window: Range to average samples over
    /// - Returns: A `HealthKitData` object containing HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getHRV(in window: ClosedRange<Date>) async throws -> HealthKitData? {

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(
            withStart: window.lowerBound,
            end: window.upperBound,
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
    
    /// Retrieves average heart rate variability across the given windows.
    ///
    /// - Parameter windows: One range per night to average over
    /// - Returns: A `HealthKitData` object containing average HRV in milliseconds, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageHRV(
        in windows: [ClosedRange<Date>],
        takingFirst count: Int
    ) async throws -> HealthKitData? {
        // One query spanning every window, then grouped in memory — see
        // `quantitySamples(of:covering:)`.
        let samples = try await quantitySamples(
            of: HKQuantityType(.heartRateVariabilitySDNN),
            covering: windows
        )

        let unit = HKUnit.secondUnit(with: .milli)

        let allValues: [Double] = windows.compactMap { window in
            let nightSamples = samples.filter { window.contains($0.startDate) }

            guard !nightSamples.isEmpty else { return nil }

            let total = nightSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) }

            return total / Double(nightSamples.count)
        }

        // Newest first, so this keeps the most recent nights that have samples
        // and treats the rest of the pool as a reserve for gaps.
        let used = Array(allValues.prefix(max(count, 1)))

        guard !used.isEmpty else { return nil }

        let average = used.reduce(0, +) / Double(used.count)
        return HealthKitData(date: windows.first?.upperBound ?? Date(), value: average)
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

        // Total active energy całego dnia (workouts + casual movement + standy).
        // Spójność z baseline z getAverageDailyActiveEnergy (też cumulativeSum total).
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
    
    public func getActiveEnergy(in window: ClosedRange<Date>) async throws -> HealthKitData? {
        guard let energy = try await getActiveEnergyForDay(
            dayStart: window.lowerBound,
            dayEnd: window.upperBound
        ) else {
            #if DEBUG
            print("🏃 Active energy: nil (no data for \(window.lowerBound) → \(window.upperBound))")
            #endif
            return nil
        }

        #if DEBUG
        print("🏃 Active energy: \(String(format: "%.0f", energy)) kcal (\(window.lowerBound) → \(window.upperBound))")
        #endif

        return HealthKitData(date: window.lowerBound, value: energy)
    }
    
    /// Retrieves average daily active energy across the given windows.
    ///
    /// - Parameter windows: One range per day to average over
    /// - Returns: A `HealthKitData` object containing average daily energy in kcal, or `nil` if unavailable
    /// - Throws: HealthKit errors if data access fails
    public func getAverageActiveEnergy(
        in windows: [ClosedRange<Date>],
        takingFirst count: Int
    ) async throws -> HealthKitData? {
        // One statistics collection bucketed per day by HealthKit itself. A task
        // group of one query per window was acceptable for a seven-day baseline
        // and does not scale to a 49-day pool, let alone a history backfill.
        // A task group also loses ordering, which `takingFirst` depends on.
        let totals = try await dailyActiveEnergyTotals(covering: windows)
        let calendar = Calendar.current

        let dailyValues: [Double] = windows.compactMap { window in
            guard let value = totals[calendar.startOfDay(for: window.lowerBound)],
                  value > 0 else {
                return nil
            }

            return value
        }

        // Newest first, so this keeps the most recent days that burned anything
        // and treats the rest of the pool as a reserve for gaps.
        let used = Array(dailyValues.prefix(max(count, 1)))

        guard !used.isEmpty else { return nil }

        let average = used.reduce(0, +) / Double(used.count)
        return HealthKitData(date: windows.first?.upperBound ?? Date(), value: average)
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
            #if DEBUG
            print("❌ No RHR data found at all in last 7 days!")
            #endif
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
                    // enumerateStatistics jest luźny na końcu — może zwrócić też bucket
                    // dla dzisiaj (jego end >= endDate). Defensywny filter incomplete day.
                    guard !calendar.isDateInToday(stats.startDate) else { return }

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
