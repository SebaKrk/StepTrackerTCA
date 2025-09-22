//
//  PersonalDataClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 22/09/2025.
//

import ComposableArchitecture
import Foundation
import HealthHub
import SharedModels

public struct PersonalDataClient {
    
    var getAge: @Sendable () async throws -> Int?
    var getBiologicalSex: @Sendable () async throws -> String?
    var getHeight: @Sendable () async throws -> HealthKitData?
    var getWeight: @Sendable (Int) async throws -> HealthKitData?
    var getRestingHeartRate: @Sendable (Int) async throws -> HealthKitData?
}

extension DependencyValues {
    var personalDataClient: PersonalDataClient {
        get { self[PersonalDataClientKey.self] }
        set { self[PersonalDataClientKey.self] = newValue }
    }
}

private enum PersonalDataClientKey: DependencyKey {
    
    static let liveValue: PersonalDataClient = {
        
        @Dependency(\.personalDataManager) var manager
        
        return PersonalDataClient(
            getAge: {
                return try await manager.getAge()
            },
            getBiologicalSex: {
                return try await manager.getBiologicalSex()
            },
            getHeight: {
                return try await manager.getHeight()
            },
            getWeight: { days in
                return try await manager.getWeight(days: days)
            },
            getRestingHeartRate: { days in
                return try await manager.getRestingHeartRate(days: days)
            }
        )
    }()
}
