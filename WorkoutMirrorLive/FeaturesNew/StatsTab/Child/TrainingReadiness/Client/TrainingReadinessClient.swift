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

public enum TrainingReadinessClientKey: DependencyKey {
    public static let liveValue: TrainingReadinessClient = {
        @Dependency(\.trainingReadinessCalculator) var calculator
        
        return TrainingReadinessClient(
            calculate: {
                try await calculator.calculateTrainingReadiness()
            },
            history: { days in
                try await calculator.getTrainingReadinessHistory(days: days)
            }
        )
    }()
}


