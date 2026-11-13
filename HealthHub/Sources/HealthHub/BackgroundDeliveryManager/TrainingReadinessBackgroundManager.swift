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

    /// The one-off history rebuild, tracked so it can be cancelled and so a
    /// second `start()` cannot launch a rebuild alongside a running one.
    private var rebuildTask: Task<Void, Never>?
    private let widgetDataClient: WidgetDataClient
    private let watchConnectivityManager: WatchConnectivityManager

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
        widgetDataClient: WidgetDataClient,
        watchConnectivityManager: WatchConnectivityManager
    ) {
        self.backgroundDeliveryManager = backgroundDeliveryManager
        self.calculator = calculator
        self.widgetDataClient = widgetDataClient
        self.watchConnectivityManager = watchConnectivityManager
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

        // Detached from start(): a one-off catch-up must not delay registering
        // background delivery, and it has no bearing on whether that succeeded.
        // Guarded rather than cancel-and-restart: restarting would throw away a
        // rebuild that is most of the way through sixty days of HealthKit reads.
        guard rebuildTask == nil else { return }

        rebuildTask = Task { [calculator] in
            do {
                let days = try await calculator.rebuildHistoryIfNeeded()

                #if DEBUG
                if days > 0 {
                    print("✅ [Readiness] history rebuilt from HealthKit: \(days) days")
                }
                #endif
            } catch {
                #if DEBUG
                print("⚠️ [Readiness] history rebuild failed: \(error)")
                #endif
            }

            await self.clearRebuildTask()
        }
    }

    /// Releases the rebuild slot once the rebuild has finished.
    private func clearRebuildTask() {
        rebuildTask = nil
    }
    
    /// Stops all background observations.
    public func stop() async throws {
        observationTask?.cancel()
        observationTask = nil

        rebuildTask?.cancel()
        rebuildTask = nil
        
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
        #if DEBUG
        print("📊 New data detected for \(type.identifier)")
        #endif
        
        // 1. Broadcast to App (Start observing features) - IMMEDIATE
        let update = HealthDataUpdate(type: type, timestamp: Date())
        for subscriber in subscribers.values {
            subscriber.yield(update)
        }
        
        // 2. Readiness publishing (widget + Watch) - DEBOUNCED
        // Debounce: skip if refreshed recently (5 minutes)
        if let lastRefresh = lastRefreshDate,
           Date().timeIntervalSince(lastRefresh) < minimumRefreshInterval {
            #if DEBUG
            print("⏭️ Skipping WIDGET refresh - debounced (last refresh: \(Int(Date().timeIntervalSince(lastRefresh)))s ago)")
            #endif
            return
        }
        
        // Marked only once something was actually published. Waiting on sleep
        // used to consume the window: the morning's four syncs arrive seconds
        // apart, so a first event fired before the night closed would block the
        // sleep event that follows — the one sync the result depends on.
        if await publishReadiness() {
            lastRefreshDate = Date()
        }
    }
    
    /// Recalculates readiness now, for a caller outside the observer path.
    ///
    /// Bypasses the debounce on purpose: a scheduled refresh already arrives at
    /// the system's pace, and the window exists to collapse the burst of observer
    /// callbacks that a morning sync fires, not to ration deliberate runs.
    ///
    /// - Returns: Whether anything reached the widget
    @discardableResult
    public func refreshNow() async -> Bool {
        await publishReadiness()
    }

    /// Recalculates readiness and feeds both consumers: the Home Screen widget
    /// and the paired Apple Watch.
    ///
    /// - Returns: Whether anything reached the widget, and the debounce window
    ///   should therefore close. A failure counts as published — retrying it on
    ///   every sample would turn a broken read into a loop.
    @discardableResult
    private func publishReadiness() async -> Bool {
        do {
            // 1. Calculate training readiness
            let outcome = try await calculator.calculateReadinessOutcome()

            // 2. Only a scored day reaches the widget and the Watch. Waiting on
            //    sleep is not an error — it just has nothing to publish yet.
            guard let result = outcome.result else {
                if case .awaitingSleepData = outcome {
                    return false
                }
                await widgetDataClient.clear()
                return true
            }

            // 3. Save to widget storage
            await widgetDataClient.saveReadinessResult(result)

            // 4. Push to the paired Watch — a missing Watch must not fail the widget path.
            do {
                try await watchConnectivityManager.publishReadinessSnapshot(
                    ReadinessSnapshot(result: result)
                )
            } catch {
                #if DEBUG
                print("❌ Failed to publish readiness to Watch: \(error.localizedDescription)")
                #endif
            }

            return true
        } catch {
            #if DEBUG
            print("❌ Failed to refresh readiness: \(error.localizedDescription)")
            #endif

            return true
        }
    }
}
