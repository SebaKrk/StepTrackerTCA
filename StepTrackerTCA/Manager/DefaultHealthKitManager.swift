//
//  DefaultHealthKitManager.swift
//  StepTrackerTCA
//
//  Created by Sebastian Sciuba on 28/12/2024.
//

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
    
    // MARK: - Methods

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
            throw error // Rethrow to notify the caller
        }
    }
    
}
