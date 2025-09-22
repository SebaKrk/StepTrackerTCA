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
}
