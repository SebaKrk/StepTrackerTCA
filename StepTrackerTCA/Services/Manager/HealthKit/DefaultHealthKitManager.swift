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
        HKQuantityType(.bodyMass),
        HKObjectType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.workoutEffortScore),
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
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async throws -> [HealthData] {
        let (startDate, endDate) = calculateDateRange(for: days)
        let query = buildQuery(for: quantityType, startDate: startDate, endDate: endDate, options: options)
        let results = try await query.result(for: store)
        return processHealthData(results.statistics(), unit: unit, options: options)
    }
    
    /// Fetches workouts from the HealthKit store for a given number of past days.
    ///
    /// - Parameter days: The number of days to look back for workouts. Defaults to 28.
    /// - Returns: An array of `HKWorkout` objects.
    func fetchWorkouts(for days: Int = 28) async throws -> [HKWorkout] {
        
        let (startDate, endDate) = calculateDateRange(for: days)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        /// HKSamplePredicate<HKWorkout>.workout(predicate)
        let workoutPredicate = HKSamplePredicate.workout(predicate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [workoutPredicate],
            sortDescriptors: [SortDescriptor(\HKWorkout.endDate, order: .reverse)]
        )
        let workouts = try await descriptor.result(for: store)
        return workouts
    }
    
    func fetchHeartRateSamples(for workout: HKWorkout) async throws -> [HKQuantitySample] {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw NSError(
                domain: "HealthKitError",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Heart Rate type is unavailable in HealthKit"]
            )
        }
        
        let objectPredicate = HKQuery.predicateForObjects(from: workout)
        
        let timePredicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: []
        )
        let compound = NSCompoundPredicate(andPredicateWithSubpredicates: [objectPredicate, timePredicate])
        let descriptor = HKSampleQueryDescriptor(
            predicates: [ .quantitySample(type: hrType, predicate: compound) ],
            sortDescriptors: [SortDescriptor(\HKQuantitySample.startDate, order: .forward) ]
        )
        return try await descriptor.result(for: store) as [HKQuantitySample]
    }
    
    func fetchActiveEnergyBurned(for workout: HKWorkout) async throws -> Double {
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate) { _, result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let sum = result?.sumQuantity() {
                    let kcal = sum.doubleValue(for: HKUnit.kilocalorie())
                    continuation.resume(returning: kcal)
                } else {
                    continuation.resume(returning: 0)
                }
            }
            self.store.execute(query)
        }
    }
    
    /// Adds health data to the HealthKit store for a specific date, value, and type.
    func addHealthData(for date: Date, value: Double, type: HKQuantityTypeIdentifier, unit: HKUnit) async throws {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            throw NSError(domain: "HealthDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid HealthKit data"])
        }
        
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: quantityType, quantity: quantity, start: date, end: date)
        
        do {
            try await store.save(sample)
            print("✅ Successfully saved \(type.rawValue) data for date \(date): value = \(value) \(unit.unitString)")
        } catch {
            print("❌ Failed to save \(type.rawValue) data for date \(date): \(error.localizedDescription)")
            throw error
        }
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
    
    /// Processes the raw statistics into health data.
    private func processHealthData(_ statistics: [HKStatistics], unit: HKUnit, options: HKStatisticsOptions) -> [HealthData] {
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
            return .init(date: $0.startDate, value: value)
        }
    }
    
    // MARK: - Mock data

    func addSimulatorData() async throws {
        var mockSamples: [HKQuantitySample] = []

        for i in 0..<28 {
            let stepQuantity = HKQuantity(unit: .count(), doubleValue: .random(in: 4_000...20_000))
            let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: .random(in: (98 + Double(i / 3)...101 + Double(i / 3))))

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


//// Define the type.
//let stepType = HKQuantityType(.stepCount)
//
//// Create the descriptor.
//let descriptor = HKSampleQueryDescriptor(
//    predicates:[.quantitySample(type: stepType)],
//    sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
//    limit: 10)
//
//
//// Launch the query and wait for the results.
//// The system automatically sets results to [HKQuantitySample].
//let results = try await descriptor.result(for: store)
//
//
//for result in results {
//    // Process the results here.
//}
