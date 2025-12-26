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
    
    // MARK: - Dependency
    
    @Dependency(\.personalDataManager) var personalDataManager
    @Dependency(\.sleepDataManager) var sleepDataManager
    
    // MARK: - Lifecycle
    
    public init() {}
    
    // MARK: - API
    
    public func calculateTrainingReadiness() async throws -> TrainingReadinessResult {
        
        let restingHeartRateComponent = try await calculateRestingHeartRateScore()
        let hrvComponent = try await calculateHRVScore()
        let sleepComponent = try await calculateSleepScore()
        let activityLoadComponent = try await calculateActivityLoadScore()

        let components = TrainingReadinessComponents(
            restingHeartRate: restingHeartRateComponent,
            heartRateVariability: hrvComponent,
            sleepQuality: sleepComponent,
            previousDayLoad: activityLoadComponent
        )
        
        let overallScore = calculateOverallScore(from: components)
        let isReliable = checkReliability(components: components)
        
        return TrainingReadinessResult(
            overallScore: overallScore,
            components: components,
            isReliable: isReliable
        )
    }
    
    public func getTrainingReadinessHistory(days: Int) async throws -> [TrainingReadinessResult] {
        return []
    }
    
    // MARK: - Private Methods
    
    private func calculateOverallScore(from components: TrainingReadinessComponents) -> Int {
        var totalScore = 50
        var componentCount = 0
        
        if let rhr = components.restingHeartRate {
            totalScore += rhr.score
            componentCount += 1
        }
        
        if let hrv = components.heartRateVariability {
            totalScore += hrv.score
            componentCount += 1
        }
        
        if let sleep = components.sleepQuality {
            totalScore += sleep.score
            componentCount += 1
        }
        
        if let load = components.previousDayLoad {
            totalScore += load.score
            componentCount += 1
        }
        
        return max(0, min(100, totalScore))
    }
    
    private func checkReliability(components: TrainingReadinessComponents) -> Bool {
        let availableComponents = [
            components.restingHeartRate,
            components.heartRateVariability,
            components.sleepQuality,
            components.previousDayLoad
        ].compactMap { $0 }.count
        
        return availableComponents >= 2 || components.restingHeartRate != nil
    }
}
