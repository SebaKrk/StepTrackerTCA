//
//  DefaultTrainingReadinessCalculator.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/09/2025.
//

import ComposableArchitecture
import Foundation
import SharedModels

@preconcurrency
public final class DefaultTrainingReadinessCalculator: TrainingReadinessCalculator, @unchecked Sendable {
    
//    @Dependency(\.personalDataManager) var personalDataManager
//    @Dependency(\.sleepDataManager) var sleepDataManager // nowy manager dla snu
//    @Dependency(\.hrvDataManager) var hrvDataManager // nowy manager dla HRV
    
    public init() {}
    
    public func calculateTrainingReadiness() async throws -> TrainingReadinessResult {
        // Implementacja algorytmu Training Readiness
    }
}
