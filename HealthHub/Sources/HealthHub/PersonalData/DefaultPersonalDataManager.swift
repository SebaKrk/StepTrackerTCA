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
    
    /// Retrieves user's biological sex directly from HealthKit characteristics as a readable string.
    public func getBiologicalSex() async throws -> String? {
        do {
            let biologicalSex = try manager.healthStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .male: return "Male"
            case .female: return "Female"
            case .other: return "Other"
            case .notSet: return "Not Set"
            @unknown default: return "Unknown"
            }
        } catch {
            print("Failed to fetch biological sex: \(error)")
            return nil
        }
    }
    
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
    public func getWeight(days: Int = 1) async throws -> HealthKitData? {
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
        
        return processedData.first
    }
    
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
}
