//
//  TrainingReadinessBackgroundManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/01/2026.
//

import HealthKit
import Foundation
import SharedModels

/// Manages background delivery specifically for Training Readiness widget.
/// Observes health data changes and updates widget when new data arrives.
public actor TrainingReadinessBackgroundManager {
    
    // MARK: - Properties
    
    private let backgroundDeliveryManager: BackgroundDeliveryManager
    private let calculator: TrainingReadinessCalculator
    private let widgetDataClient: WidgetDataClient
    
    /// Health data types needed for training readiness calculation
    private let observedTypes: Set<HKSampleType> = [
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.activeEnergyBurned)
    ]
    
    /// Task tracking all observations
    private var observationTask: Task<Void, Never>?
    
    /// Last refresh timestamp to implement debouncing
    private var lastRefreshDate: Date?
    
    /// Minimum time between refreshes (5 minutes)
    private let minimumRefreshInterval: TimeInterval = 300
    
    // MARK: - Lifecycle
    
    public init(
        backgroundDeliveryManager: BackgroundDeliveryManager,
        calculator: TrainingReadinessCalculator,
        widgetDataClient: WidgetDataClient
    ) {
        self.backgroundDeliveryManager = backgroundDeliveryManager
        self.calculator = calculator
        self.widgetDataClient = widgetDataClient
    }
    
    // MARK: - Public API
    
    /// Starts background delivery and observation for training readiness data.
    ///
    /// This method:
    /// 1. Enables background delivery for all required health types
    /// 2. Creates observation streams for each type
    /// 3. Refreshes widget when new data arrives (with debouncing)
    ///
    /// - Throws: HealthKit errors if background delivery cannot be enabled
    public func start() async throws {
        try await backgroundDeliveryManager.enable(
            for: observedTypes,
            frequency: .immediate
        )
        
        observationTask = Task {
            await withTaskGroup(of: Void.self) { group in
                for type in observedTypes {
                    group.addTask {
                        await self.observeType(type)
                    }
                }
            }
        }
    }
    
    /// Stops all background observations.
    public func stop() async throws {
        observationTask?.cancel()
        observationTask = nil
        
        try await backgroundDeliveryManager.disable(for: observedTypes)
    }
    
    // MARK: - Private Helpers
    
    private func observeType(_ type: HKSampleType) async {
        let stream = await backgroundDeliveryManager.observationStream(for: type)
        
        for await _ in stream {
            await handleNewData(for: type)
        }
    }
    
    private func handleNewData(for type: HKSampleType) async {
        // Debounce: skip if refreshed recently
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            print("⏭️ Skipping refresh - debounced (last refresh: \(Int(Date().timeIntervalSince(lastRefresh)))s ago)")
            return
        }
        
        await refreshWidget()
    }
    
    private func refreshWidget() async {
        do {
            let result = try await calculator.calculateTrainingReadiness()
            guard !result.hasInsufficientData else {
                await widgetDataClient.clear()
                return
            }
            await widgetDataClient.saveReadinessResult(result)
            
            lastRefreshDate = Date()
        } catch {
            print("❌ Failed to refresh widget: \(error.localizedDescription)")
        }
    }
}
