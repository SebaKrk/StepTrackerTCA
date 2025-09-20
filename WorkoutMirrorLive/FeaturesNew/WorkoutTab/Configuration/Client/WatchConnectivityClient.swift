//
//  WatchConnectivityClient.swift
//  MyFitnessJournal
//
//  Created by Sebastian Sciuba on 17/09/2025.
//


import ComposableArchitecture
import HealthHub
//import WatchConnectivity
import Foundation

/// Klient WatchConnectivity dla TCA - most między TCA Feature a WatchConnectivityManager
/// Zawiera funkcje które TCA może wywoływać jako Effects
public struct WatchConnectivityClient: Sendable {
    
    /// Triggeruje inicjalizację WatchConnectivity managera
    public var initializeWatchConnectivity: @Sendable () async -> Void
    
    /// Sprawdza pełny status połączenia
    public var checkWatchStatus: @Sendable () async -> WatchConnectivityStatus
    
    public var stopWatchConnectivity: @Sendable () async -> Void
}

// MARK: - Dependency Registration

/// Klucz do rejestracji WatchConnectivityClient w TCA Dependency System
public enum WatchConnectivityClientKey: DependencyKey {
    
    /// Live implementation - rzeczywisty WatchConnectivityClient który używa prawdziwego WatchConnectivityManager
    public static let liveValue: WatchConnectivityClient = {
        
        /// Pobieramy WatchConnectivityManager z TCA dependencies
        @Dependency(\.watchConnectivityManager) var watchManager
        
        return WatchConnectivityClient(
            /// Inicjalizuje WatchConnectivity manager
            initializeWatchConnectivity: {
                print("🍎 WatchConnectivityClient: Initializing WatchConnectivity...")
                await watchManager.initializeWatchConnectivity()
            },
            
            /// Sprawdza pełny status
            checkWatchStatus: {
                print("🍎 WatchConnectivityClient: Checking watch status...")
                return await watchManager.checkConnectionStatus()
            },
            
            /// konczy
            stopWatchConnectivity: {
                return await watchManager.stopWatchConnectivity()
            }
        )
    }()
}

/// Rozszerzenie TCA DependencyValues żeby można było używać watchConnectivityClient
public extension DependencyValues {
    var watchConnectivityClient: WatchConnectivityClient {
        get { self[WatchConnectivityClientKey.self] }
        set { self[WatchConnectivityClientKey.self] = newValue }
    }
}
