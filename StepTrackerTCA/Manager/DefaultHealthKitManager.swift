//
//  DefaultHealthKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

import Algorithms
import HealthKit
import Observation

/// The default implementation of the `HealthKitManager` protocol.
///
/// This class provides the necessary configuration and functionality for requesting
/// and managing HealthKit data, such as step count and body mass.
@Observable
class DefaultHealthKitManager: HealthKitManager {
    
    // MARK: - Properties
    
    /// The HealthKit store used to access and manage HealthKit data.
    ///
    /// `HKHealthStore` is responsible for interacting with the HealthKit framework.
    /// It is used for requesting permissions, fetching, and saving data.
    let store = HKHealthStore()
    
    /// A set of sample types that the manager requests write access to.
    ///
    /// This defines which types of data the app can write to HealthKit. For example,
    /// this implementation supports writing step count and body mass data.
    let shareTypes: Set<HKSampleType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass)
    ]
    
    /// A set of object types that the manager requests read access to.
    ///
    /// This defines which types of data the app can read from HealthKit. For example,
    /// this implementation supports reading step count and body mass data.
    let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass)
    ]
    
    // MARK: - API
    
    /// Requests authorization to access HealthKit data.
    ///
    /// - Returns: A result of type `Result<Bool, Error>` indicating success or an authorization error.
    func requestAuthorization() async -> Result<Bool, Error> {
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    /// Fetches data for the given quantity type and date range.
    func fetchHealthData(
        for quantityType: HKQuantityTypeIdentifier,
        days: Int = 28,
        unit: HKUnit
    ) async throws -> [HealthData] {
        let (startDate, endDate) = calculateDateRange(for: days)
        let query = buildQuery(for: quantityType, startDate: startDate, endDate: endDate)
        let results = try await query.result(for: store)
        return processHealthData(results.statistics(), unit: unit)
    }
    
    /// Calculates the average value of health data for each weekday.
    func averageWeekdayCount(for healthData: [HealthData]) -> [WeekdayChartData] {
        let sortedByWeekday = healthData.sorted { $0.date.weekdayInt < $1.date.weekdayInt }
        let weekdayArray = sortedByWeekday.chunked { $0.date.weekdayInt == $1.date.weekdayInt }

        var weekdayChartData: [WeekdayChartData] = []

        for array in weekdayArray {
            guard let firstValue = array.first else { continue }
            let total = array.reduce(0) { $0 + $1.value }
            let avgSteps = total/Double(array.count)

            weekdayChartData.append(.init(date: firstValue.date, value: avgSteps))
        }

        return weekdayChartData
    }
    
    // MARK: - Private Helpers

    /// Calculates the date range for the last `days` days.
    private func calculateDateRange(for days: Int) -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let endDate = calendar.date(byAdding: .day, value: 1, to: today)!
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate)!
        return (startDate, endDate)
    }

    /// Builds a query for the given quantity type and date range.
    private func buildQuery(
        for quantityType: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date
    ) -> HKStatisticsCollectionQueryDescriptor {
        let type = HKQuantityType(quantityType)
        let queryPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: queryPredicate)
        return HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: .init(day: 1)
        )
    }

    /// Processes the raw statistics into health data.
    private func processHealthData(_ statistics: [HKStatistics], unit: HKUnit) -> [HealthData] {
        statistics.map {
            .init(date: $0.startDate, value: $0.sumQuantity()?.doubleValue(for: unit) ?? 0)
        }
    }
    
    // MARK: - Mock data

    func addSimulatorData() async throws {
        var mockSamples: [HKQuantitySample] = []

        for i in 0..<28 {
            let stepQuantity = HKQuantity(unit: .count(), doubleValue: .random(in: 4_000...20_000))
            let weightQuantity = HKQuantity(unit: .pound(), doubleValue: .random(in: (160 + Double(i / 3)...165 + Double(i / 3))))

            guard let startDate = Calendar.current.date(byAdding: .day, value: -i, to: .now),
                  let endDate = Calendar.current.date(byAdding: .second, value: 1, to: startDate) else {
                continue
            }

            let stepSample = HKQuantitySample(type: HKQuantityType(.stepCount), quantity: stepQuantity, start: startDate, end: endDate)
            let weightSample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: weightQuantity, start: startDate, end: endDate)

            mockSamples.append(stepSample)
            mockSamples.append(weightSample)
        }

        do {
            try await store.save(mockSamples)
            print("✅ Dummy Data successfully sent up")
        } catch {
            print("❌ Failed to save dummy data: \(error.localizedDescription)")
            throw error
        }
    }
    
}
