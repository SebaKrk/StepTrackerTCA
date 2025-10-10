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
        
        // DEBUG - wylistuj wszystkie RHR
        try await personalDataManager.debugListAllRHR()
        
        // 1. Pobierz dane z HealthKit
        let restingHeartRateComponent = try await calculateRestingHeartRateScore()
        let hrvComponent = try await calculateHRVScore()
        let sleepComponent = try await calculateSleepScore()
        let activityLoadComponent = try await calculateActivityLoadScore() // ← DODAJ
        
        // 2. Zbuduj components
        let components = TrainingReadinessComponents(
            restingHeartRate: restingHeartRateComponent,
            heartRateVariability: hrvComponent,
            sleepQuality: sleepComponent,
            previousDayLoad: activityLoadComponent // ← DODAJ
        )
        
        // Debug: Sprawdź które komponenty są dostępne
        print("🔍 Training Readiness Debug:")
        print("  - RHR: \(restingHeartRateComponent != nil ? "✅ \(restingHeartRateComponent!.score)" : "❌ nil")")
        print("  - HRV: \(hrvComponent != nil ? "✅ \(hrvComponent!.score)" : "❌ nil")")
        print("  - Sleep: \(sleepComponent != nil ? "✅ \(sleepComponent!.score)" : "❌ nil")")
        print("  - Activity: \(activityLoadComponent != nil ? "✅ \(activityLoadComponent!.score)" : "❌ nil")")
        
        
        // 3. Oblicz overall score
        let overallScore = calculateOverallScore(from: components)
        
        // 4. Sprawdź reliability
        let isReliable = checkReliability(components: components)
        
        // 5. Zwróć wynik
        return TrainingReadinessResult(
            overallScore: overallScore,
            components: components,
            isReliable: isReliable
        )
    }
    
    public func getTrainingReadinessHistory(days: Int) async throws -> [TrainingReadinessResult] {
        // TODO: Implementacja historii
        return []
    }
    
    // MARK: - Private Methods
    
    /// Oblicza końcowy overall score z wszystkich komponentów
    private func calculateOverallScore(from components: TrainingReadinessComponents) -> Int {
        var totalScore = 50 // bazowy score
        var componentCount = 0
        
        // Dodaj score z każdego dostępnego komponentu
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
        
        // Ogranicz wynik do zakresu 0-100
        return max(0, min(100, totalScore))
    }
    
    /// Sprawdza czy wynik jest wiarygodny (czy mamy wystarczająco danych)
    private func checkReliability(components: TrainingReadinessComponents) -> Bool {
        let availableComponents = [
            components.restingHeartRate,
            components.heartRateVariability,
            components.sleepQuality,
            components.previousDayLoad
        ].compactMap { $0 }.count
        
        // Uznajemy za wiarygodne jeśli mamy przynajmniej 2 komponenty
        // Lub jeśli mamy RHR (najważniejszy wskaźnik)
        return availableComponents >= 2 || components.restingHeartRate != nil
    }
}
