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
    
    // MARK: - App Broadcasting

    /// Active stream continuations for app updates
    private var subscribers: [UUID: AsyncStream<HealthDataUpdate>.Continuation] = [:]
    
    /// Creates a stream of health data updates for the main app.
    /// Use this to subscribe to real-time changes in features like StatsView.
    public func healthDataUpdates() -> AsyncStream<HealthDataUpdate> {
        AsyncStream { continuation in
            let id = UUID()
            self.subscribers[id] = continuation
            
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.removeSubscriber(id: id)
                }
            }
        }
    }
    
    private func removeSubscriber(id: UUID) {
        subscribers.removeValue(forKey: id)
    }

    // MARK: - Private Helpers
    
    private func observeType(_ type: HKSampleType) async {
        let stream = await backgroundDeliveryManager.observationStream(for: type)
        
        for await _ in stream {
            await handleNewData(for: type)
        }
    }
    
    private func handleNewData(for type: HKSampleType) async {
        print("📊 New data detected for \(type.identifier)")
        
        // 1. Broadcast to App (Start observing features) - IMMEDIATE
        let update = HealthDataUpdate(type: type, timestamp: Date())
        for subscriber in subscribers.values {
            subscriber.yield(update)
        }
        
        // 2. Widget Refresh - DEBOUNCED
        // Debounce: skip if refreshed recently (5 minutes)
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            print("⏭️ Skipping WIDGET refresh - debounced (last refresh: \(Int(Date().timeIntervalSince(lastRefresh)))s ago)")
            return
        }
        
        // Update timestamp immediately to block subsequent WIDGET refresh calls
        lastRefreshDate = Date()
        
        await refreshWidget()
    }
    
    private func refreshWidget() async {
        print("🔄 Refreshing Training Readiness widget...")
        
        do {
            // 1. Calculate training readiness
            let result = try await calculator.calculateTrainingReadiness()
            
            // 2. Check if we have sufficient data
            guard !result.hasInsufficientData else {
                print("⚠️ Insufficient data for training readiness")
                await widgetDataClient.clear()
                return
            }
            
            // 3. Save to widget storage
            await widgetDataClient.saveReadinessResult(result)
            
            print("✅ Widget refreshed successfully - Score: \(result.overallScore)")
            
        } catch {
            print("❌ Failed to refresh widget: \(error.localizedDescription)")
        }
    }
}
