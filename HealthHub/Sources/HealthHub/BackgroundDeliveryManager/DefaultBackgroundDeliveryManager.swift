//
//  DefaultBackgroundDeliveryManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 28/01/2026.
//

import HealthKit

public actor DefaultBackgroundDeliveryManager: BackgroundDeliveryManager {
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore
    
    /// Active observer queries - kept alive to continue receiving updates
    private var observerQueries: [HKSampleType: HKObserverQuery] = [:]
    
    /// Stream continuations for each observed type
    private var streamContinuations: [HKSampleType: AsyncStream<Void>.Continuation] = [:]
    
    /// Track which types have background delivery enabled
    private var enabledTypes: Set<HKSampleType> = []
    
    // MARK: - Lifecycle
    
    public init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    // MARK: - BackgroundDeliveryManager Protocol
    
    public func enable(
        for types: Set<HKSampleType>,
        frequency: HKUpdateFrequency
    ) async throws {
        for type in types {
            try await enableBackgroundDelivery(for: type, frequency: frequency)
            enabledTypes.insert(type)
        }
    }
    
    public func disable(for types: Set<HKSampleType>) async throws {
        for type in types {
            try await disableBackgroundDelivery(for: type)
            enabledTypes.remove(type)
        }
    }
    
    public func observationStream(for type: HKSampleType) async -> AsyncStream<Void> {
        if let existingQuery = observerQueries[type] {
            print("⚠️ Stream already exists for \(type.identifier) - stopping old one")
            healthStore.stop(existingQuery)
            streamContinuations[type]?.finish()
        }
        
        let healthStore = self.healthStore
        
        return AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }
            
            // Create observer query inline
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
                guard error == nil else {
                    print("❌ Observer query error for \(type.identifier): \(error!.localizedDescription)")
                    completionHandler()
                    return
                }
                
                /// print("🔔 New data available for \(type.identifier)")
                continuation.yield()
                completionHandler()
            }
            
            Task {
                await self.storeStreamContinuation(continuation, for: type)
                await self.storeObserverQuery(query, for: type)
                healthStore.execute(query)
            }
            
            continuation.onTermination = { @Sendable _ in
                Task { await self.stopObserving(type: type) }
            }
        }
    }
    
    public func isEnabled(for type: HKSampleType) async -> Bool {
        enabledTypes.contains(type)
    }
    
    // MARK: - Private Helpers
    
    private func enableBackgroundDelivery(
        for type: HKSampleType,
        frequency: HKUpdateFrequency
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.enableBackgroundDelivery(
                for: type,
                frequency: frequency
            ) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    /// print("✅ Background delivery enabled for \(type.identifier)")
                    continuation.resume()
                } else {
                    continuation.resume(throwing: BackgroundDeliveryError.enableFailed)
                }
            }
        }
    }
    
    private func disableBackgroundDelivery(for type: HKSampleType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.disableBackgroundDelivery(for: type) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    /// print("✅ Background delivery disabled for \(type.identifier)")
                    continuation.resume()
                } else {
                    continuation.resume(throwing: BackgroundDeliveryError.disableFailed)
                }
            }
        }
    }
    
    private func storeStreamContinuation(
        _ continuation: AsyncStream<Void>.Continuation,
        for type: HKSampleType
    ) {
        streamContinuations[type] = continuation
    }
    
    private func storeObserverQuery(
        _ query: HKObserverQuery,
        for type: HKSampleType
    ) {
        observerQueries[type] = query
    }
    
    private func stopObserving(type: HKSampleType) {
        if let query = observerQueries[type] {
            healthStore.stop(query)
            observerQueries.removeValue(forKey: type)
            print("🛑 Stopped observing \(type.identifier)")
        }
        
        streamContinuations[type]?.finish()
        streamContinuations.removeValue(forKey: type)
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Stop all queries
        for query in observerQueries.values {
            healthStore.stop(query)
        }
        
        // Finish all streams
        for continuation in streamContinuations.values {
            continuation.finish()
        }
    }
}

// MARK: - Error

public enum BackgroundDeliveryError: Error {
    case enableFailed
    case disableFailed
}
