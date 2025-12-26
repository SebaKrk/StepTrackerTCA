//
//  TrainingReadinessClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 29/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels
import HealthHub

/// Client interface for training readiness calculations in TCA architecture.
///
/// `TrainingReadinessClient` acts as a bridge between the TCA feature layer and
/// the underlying HealthKit service layer, providing a dependency-injectable
/// interface for training readiness operations.
///
/// ## Usage in Reducers
/// ```swift
/// @Dependency(\.trainingReadinessClient) var trainingReadinessClient
///
/// case .calculateReadiness:
///     return .run { send in
///         let result = try await trainingReadinessClient.calculate()
///         await send(.readinessCalculated(result))
///     }
/// ```
@DependencyClient
public struct TrainingReadinessClient: Sendable {
    
    /// Calculates current training readiness based on available health data.
    ///
    /// - Returns: `TrainingReadinessResult` containing overall score and component breakdown
    /// - Throws: Errors if HealthKit access fails or calculation encounters issues
    public var calculate: @Sendable () async throws -> TrainingReadinessResult
    
    /// Retrieves historical training readiness data.
    ///
    /// - Parameter days: Number of days of historical data to retrieve
    /// - Returns: Array of `TrainingReadinessResult` ordered chronologically
    /// - Throws: Errors if HealthKit access fails or calculation encounters issues
    public var history: @Sendable (_ days: Int) async throws -> [TrainingReadinessResult]
}

public extension DependencyValues {
    var trainingReadinessClient: TrainingReadinessClient {
        get { self[TrainingReadinessClientKey.self] }
        set { self[TrainingReadinessClientKey.self] = newValue }
    }
}
//
//public enum TrainingReadinessClientKey: DependencyKey {
//    public static let liveValue: TrainingReadinessClient = {
//        @Dependency(\.trainingReadinessCalculator) var calculator
//        
//        return TrainingReadinessClient(
//            calculate: {
//                return try await calculator.calculateTrainingReadiness()
//            },
//            history: { days in
//                try await calculator.getTrainingReadinessHistory(days: days)
//            }
//        )
//    }()
//    
//    public static let testValue = TrainingReadinessClient.mock
//}

//public enum TrainingReadinessClientKey: DependencyKey {
//    public static let liveValue: TrainingReadinessClient = {
//        @Dependency(\.trainingReadinessCalculator) var calculator
//        
//        let cache = LockIsolated<TrainingReadinessResult?>(nil)
//        
//        return TrainingReadinessClient(
//            calculate: {
//                // Zwróć z cache jeśli już mamy
//                if let cached = cache.value {
//                    print("📦 TrainingReadinessClient - returning CACHED result")
//                    return cached
//                }
//                
//                print("🔄 TrainingReadinessClient - fetching NEW result")
//                let result = try await calculator.calculateTrainingReadiness()
//                cache.setValue(result)
//                return result
//            },
//            history: { days in
//                try await calculator.getTrainingReadinessHistory(days: days)
//            }
//        )
//    }()
//}

public enum TrainingReadinessClientKey: DependencyKey {
    public static let liveValue: TrainingReadinessClient = {
        @Dependency(\.trainingReadinessCalculator) var calculator
        
        let cache = LockIsolated<TrainingReadinessResult?>(nil)
        let inFlight = LockIsolated<Task<TrainingReadinessResult, Error>?>(nil)
        
        return TrainingReadinessClient(
            calculate: {
                // 1. Zwróć z cache jeśli mamy
                if let cached = cache.value {
                    print("📦 TrainingReadinessClient - returning CACHED")
                    return cached
                }
                
                // 2. Jeśli już trwa request, poczekaj na niego
                if let existingTask = inFlight.value {
                    print("⏳ TrainingReadinessClient - waiting for IN-FLIGHT request")
                    return try await existingTask.value
                }
                
                // 3. Nowy request
                print("🔄 TrainingReadinessClient - fetching NEW")
                let task = Task {
                    try await calculator.calculateTrainingReadiness()
                }
                inFlight.setValue(task)
                
                let result = try await task.value
                cache.setValue(result)
                inFlight.setValue(nil)
                
                return result
            },
            history: { days in
                try await calculator.getTrainingReadinessHistory(days: days)
            }
        )
    }()
}
