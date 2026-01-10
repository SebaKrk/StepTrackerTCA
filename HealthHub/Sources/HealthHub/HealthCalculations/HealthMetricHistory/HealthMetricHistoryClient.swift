//
//  HealthMetricHistoryClient.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 10/01/2026.
//

import ComposableArchitecture
import Foundation
import SharedModels

/// Client do pobierania danych historycznych dla konkretnej metryki zdrowotnej
@DependencyClient
public struct HealthMetricHistoryClient: Sendable {
    
    /// Pobiera surowe dane historyczne dla konkretnej metryki
    /// - Parameters:
    ///   - metricType: Typ metryki (RHR, HRV, Sleep, Activity)
    ///   - days: Liczba dni wstecz
    /// - Returns: Tablica punktów danych historycznych (bez nil)
    public var fetchHistory: @Sendable (_ metricType: HealthMetricType, _ days: Int) async throws -> [HistoricalDataPoint]
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var healthMetricHistoryClient: HealthMetricHistoryClient {
        get { self[HealthMetricHistoryClientKey.self] }
        set { self[HealthMetricHistoryClientKey.self] = newValue }
    }
}

// MARK: - Dependency Key

public enum HealthMetricHistoryClientKey: DependencyKey {
    public static let liveValue: HealthMetricHistoryClient = {
        
        @Dependency(\.personalDataManager) var personalDataManager
        
        @Dependency(\.sleepDataManager) var sleepDataManager
        
        return HealthMetricHistoryClient(
            fetchHistory: { metricType, days in
                
                let healthKitDataArray: [HealthKitData?]
                switch metricType {
                case .rhr:
                    healthKitDataArray = try await personalDataManager.getRestingHeartRateHistory(days: days)
                    
                case .hrv:
                    healthKitDataArray = try await personalDataManager.getHeartRateVariabilityHistory(nights: days)
                    
                case .sleep:
                    healthKitDataArray = try await sleepDataManager.getSleepHistory(nights: days)
                    
                case .activity:
                    healthKitDataArray = try await personalDataManager.getActiveEnergyBurnedHistory(days: days)
                }
                
                return healthKitDataArray.compactMap { data in
                    guard let data = data else { return nil }
                    return HistoricalDataPoint(date: data.date, value: data.value)
                }
            }
        )
    }()
    
    public static let testValue = HealthMetricHistoryClient()
}

public extension HealthMetricHistoryClient {
    static let mock = HealthMetricHistoryClient(
        fetchHistory: { metricType, days in
            // Mock data dla testów - przykładowe wartości dla każdego typu
            let calendar = Calendar.current
            
            return (0..<days).compactMap { daysAgo in
                guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else {
                    return nil
                }
                
                let mockValue: Double
                switch metricType {
                case .rhr:
                    mockValue = Double.random(in: 50...70) // RHR w bpm
                case .hrv:
                    mockValue = Double.random(in: 30...80) // HRV w ms
                case .sleep:
                    mockValue = Double.random(in: 6.0...9.0) // Sleep w godzinach
                case .activity:
                    mockValue = Double.random(in: 200...600) // Active Energy w kcal
                }
                
                return HistoricalDataPoint(date: date, value: mockValue)
            }.reversed()
        }
    )
}
