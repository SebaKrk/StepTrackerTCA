//
//  HealthKitQueryBuilder.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import HealthKit
import SharedModels

/// A utility class for building and executing HealthKit queries with standardized processing.
///
/// `HealthKitQueryBuilder` provides reusable static methods for common HealthKit operations,
/// including date range calculations, query construction, and data processing. This eliminates
/// code duplication across different health data managers and ensures consistent query behavior
/// throughout the application.
///
/// ## Overview
/// The builder follows a three-step process:
/// 1. **Calculate date range** - Define the time period for data retrieval
/// 2. **Build query** - Create the appropriate HealthKit query descriptor
/// 3. **Process results** - Convert raw HealthKit statistics to application models
///
/// ## Example Usage
/// ```swift
/// // Get average weight from last 7 days
/// let (startDate, endDate) = HealthKitQueryBuilder.calculateDateRange(for: 7)
/// let query = HealthKitQueryBuilder.buildQuery(
///     for: .bodyMass,
///     startDate: startDate,
///     endDate: endDate,
///     options: .discreteAverage
/// )
/// let results = try await query.result(for: healthStore)
/// let processedData = HealthKitQueryBuilder.processHealthKitData(
///     results.statistics(),
///     unit: .gramUnit(with: .kilo),
///     options: .discreteAverage
/// )
/// ```
public final class HealthKitQueryBuilder {
    
    /// Calculates the date range for the last specified number of days.
    ///
    /// This method creates a date range starting from the specified number of days ago
    /// and ending at the end of today. The range uses start of day calculations to
    /// ensure consistent daily boundaries.
    ///
    /// - Parameter days: The number of days to look back from today
    /// - Returns: A tuple containing the start date and end date for the range
    ///
    /// ## Example
    /// ```swift
    /// let (start, end) = HealthKitQueryBuilder.calculateDateRange(for: 7)
    /// // Returns: 7 days ago at 00:00:00 to tomorrow at 00:00:00
    /// ```
    public static func calculateDateRange(for days: Int) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let endDate = calendar.date(byAdding: .day, value: 1, to: today)!
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        return (startDate, endDate)
    }

    /// Builds a statistics collection query descriptor for the specified parameters.
    ///
    /// This method creates an `HKStatisticsCollectionQueryDescriptor` that groups data by day
    /// and applies the specified statistics options. The query is optimized for retrieving
    /// daily aggregated health data over a time period.
    ///
    /// - Parameters:
    ///   - quantityType: The type of health data to query (e.g., `.bodyMass`, `.stepCount`)
    ///   - startDate: The beginning of the date range for the query
    ///   - endDate: The end of the date range for the query
    ///   - options: The statistics options to apply (`.discreteAverage` or `.cumulativeSum`)
    /// - Returns: A configured `HKStatisticsCollectionQueryDescriptor` ready for execution
    ///
    /// ## Statistics Options
    /// - **`.discreteAverage`**: Use for measurements like weight, height, heart rate
    /// - **`.cumulativeSum`**: Use for countable activities like steps, calories burned
    public static func buildQuery(
        for quantityType: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        options: HKStatisticsOptions
    ) -> HKStatisticsCollectionQueryDescriptor {
        let type = HKQuantityType(quantityType)
        let queryPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: queryPredicate)
        return HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate,
            options: options,
            anchorDate: endDate,
            intervalComponents: .init(day: 1)
        )
    }
    
    /// Processes raw HealthKit statistics into standardized HealthKitData models.
    ///
    /// This method serves as a converter between HealthKit's raw `HKStatistics` objects
    /// and the application's `HealthKitData` model. It extracts the appropriate statistical
    /// value based on the specified options and converts units as needed.
    ///
    /// - Parameters:
    ///   - statistics: Array of `HKStatistics` returned from a HealthKit query
    ///   - unit: The `HKUnit` to use for value conversion
    ///   - options: The statistics options that determine which value to extract
    /// - Returns: Array of `HealthKitData` objects with converted values and dates
    ///
    /// ## Processing Logic
    /// The method extracts different values based on the statistics options:
    ///
    /// **`.discreteAverage`** (for measurements):
    /// - Extracts the average of all samples within each day
    /// - Example: Multiple weight measurements → daily average weight
    ///
    /// **`.cumulativeSum`** (for activities):
    /// - Extracts the total sum of all samples within each day
    /// - Example: Multiple step counts → total daily steps
    ///
    /// ## Example
    /// ```swift
    /// // Convert weight statistics to HealthKitData
    /// let healthKitData = HealthKitQueryBuilder.processHealthKitData(
    ///     statistics,
    ///     unit: .gramUnit(with: .kilo),
    ///     options: .discreteAverage
    /// )
    /// // Result: [HealthKitData(date: today, value: 75.2), ...]
    /// ```
    public static func processHealthKitData(_ statistics: [HKStatistics], unit: HKUnit, options: HKStatisticsOptions) -> [HealthKitData] {
        statistics.map {
            let value: Double
            switch options {
            case .discreteAverage:
                value = $0.averageQuantity()?.doubleValue(for: unit) ?? 0
            case .cumulativeSum:
                value = $0.sumQuantity()?.doubleValue(for: unit) ?? 0
            default:
                value = 0
            }
            return HealthKitData(date: $0.startDate, value: value)
        }
    }
    
    /// Fetches workouts from HealthKit within the specified date range.
    ///
    /// This method retrieves all workout samples that occurred between the start and end dates.
    /// It's useful for analyzing training load, calculating workout-specific energy expenditure,
    /// or retrieving workout metadata.
    ///
    /// - Parameters:
    ///   - startDate: The beginning of the date range for workout retrieval
    ///   - endDate: The end of the date range for workout retrieval
    ///   - healthStore: The `HKHealthStore` instance to execute the query against
    /// - Returns: Array of `HKWorkout` objects found within the specified range
    /// - Throws: HealthKit errors if data access fails
    public static func fetchWorkouts(from startDate: Date, to endDate: Date, healthStore: HKHealthStore) async throws -> [HKWorkout] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let query = HKSampleQuery(
                sampleType: .workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetches workouts from HealthKit using the descriptor-based API.
    ///
    /// This method uses `HKSampleQueryDescriptor` which provides:
    /// - Native async/await support without continuations
    /// - Type-safe KeyPath-based sorting
    /// - Composable predicate system
    /// - Better compiler checking and code readability
    ///
    /// - Parameters:
    ///   - startDate: The beginning of the date range for workout retrieval
    ///   - endDate: The end of the date range for workout retrieval
    ///   - sortDescriptors: Array of sort descriptors to order results (default: by endDate descending)
    ///   - healthStore: The `HKHealthStore` instance to execute the query against
    /// - Returns: Array of `HKWorkout` objects sorted according to provided descriptors
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Example
    /// ```swift
    /// // Default sorting (newest first)
    /// let workouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
    ///     from: start,
    ///     to: end,
    ///     healthStore: healthStore
    /// )
    ///
    /// // Custom sorting (longest workouts first)
    /// let workouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
    ///     from: start,
    ///     to: end,
    ///     sortDescriptors: [SortDescriptor(\HKWorkout.duration, order: .reverse)],
    ///     healthStore: healthStore
    /// )
    ///
    /// // Multiple sort criteria
    /// let workouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
    ///     from: start,
    ///     to: end,
    ///     sortDescriptors: [
    ///         SortDescriptor(\HKWorkout.workoutActivityType, order: .forward),
    ///         SortDescriptor(\HKWorkout.endDate, order: .reverse)
    ///     ],
    ///     healthStore: healthStore
    /// )
    /// ```
    public static func fetchWorkoutsWithDescriptor(
        from startDate: Date,
        to endDate: Date,
        sortDescriptors: [SortDescriptor<HKWorkout>] = [SortDescriptor(\HKWorkout.endDate, order: .reverse)],
        healthStore: HKHealthStore
    ) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        let workoutPredicate = HKSamplePredicate.workout(predicate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [workoutPredicate],
            sortDescriptors: sortDescriptors
        )
        return try await descriptor.result(for: healthStore)
    }

    /// Fetches workouts from the last specified number of days using the descriptor-based API.
    ///
    /// Convenience method that automatically calculates the date range for the specified
    /// number of days and fetches workouts.
    ///
    /// - Parameters:
    ///   - days: Number of days to look back from today (default: 28)
    ///   - sortDescriptors: Array of sort descriptors to order results (default: by endDate descending)
    ///   - healthStore: The `HKHealthStore` instance to execute the query against
    /// - Returns: Array of `HKWorkout` objects from the specified period
    /// - Throws: HealthKit errors if data access fails
    ///
    /// ## Example
    /// ```swift
    /// // Fetch last 14 days with default sorting
    /// let workouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
    ///     for: 14,
    ///     healthStore: healthStore
    /// )
    ///
    /// // Fetch last 7 days sorted by duration
    /// let workouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
    ///     for: 7,
    ///     sortDescriptors: [SortDescriptor(\HKWorkout.duration, order: .reverse)],
    ///     healthStore: healthStore
    /// )
    /// ```
    public static func fetchWorkoutsWithDescriptor(
        for days: Int = 28,
        sortDescriptors: [SortDescriptor<HKWorkout>] = [SortDescriptor(\HKWorkout.endDate, order: .reverse)],
        healthStore: HKHealthStore
    ) async throws -> [HKWorkout] {
        let (startDate, endDate) = calculateDateRange(for: days)
        return try await fetchWorkoutsWithDescriptor(
            from: startDate,
            to: endDate,
            sortDescriptors: sortDescriptors,
            healthStore: healthStore
        )
    }
    
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXAMPLE 1: Recent workouts for dashboard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//let recentWorkouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
//    for: 7,
//    sortDescriptors: [SortDescriptor(\HKWorkout.endDate, order: .reverse)],
//    healthStore: healthStore
//)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXAMPLE 2: Personal records (longest runs)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//let longestRuns = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
//    for: 365,
//    sortDescriptors: [SortDescriptor(\HKWorkout.duration, order: .reverse)],
//    healthStore: healthStore
//)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXAMPLE 3: Activity summary grouped by type
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//let groupedWorkouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
//    for: 30,
//    sortDescriptors: [
//        SortDescriptor(\HKWorkout.workoutActivityType, order: .forward),
//        SortDescriptor(\HKWorkout.endDate, order: .reverse)
//    ],
//    healthStore: healthStore
//)
// Result: All running workouts (newest first), then all cycling (newest first), etc.

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXAMPLE 4: Training history (chronological order)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//let chronologicalWorkouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
//    for: 90,
//    sortDescriptors: [SortDescriptor(\HKWorkout.startDate, order: .forward)],
//    healthStore: healthStore
//)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// EXAMPLE 5: Quick workouts for beginners
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//let quickWorkouts = try await HealthKitQueryBuilder.fetchWorkoutsWithDescriptor(
//    for: 30,
//    sortDescriptors: [SortDescriptor(\HKWorkout.duration, order: .forward)],
//    healthStore: healthStore
//)
