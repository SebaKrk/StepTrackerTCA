//
//  WatchConnectivityManager.swift
//  HealthHub
//
//  Created by Sebastian Sciuba on 17/09/2025.
//

import WatchConnectivity

/// Protokół dla zarządzania WatchConnectivity Manager
public protocol WatchConnectivityManager: Sendable {
    
    /// Czy WatchConnectivity jest obsługiwane
    var isSupported: Bool { get async }
    
    /// Czy Apple Watch jest sparowany
    var isPaired: Bool { get async }
    
    /// Czy aplikacja Watch jest zainstalowana
    var isWatchAppInstalled: Bool { get async }
    
    /// Czy można komunikować się z Watch
    var isReachable: Bool { get async }
    
    /// Aktualny status połączenia
    var currentStatus: WatchConnectivityStatus { get async }
    
    /// Inicjalizuje WatchConnectivity session
    func initializeWatchConnectivity() async
    
    /// Sprawdza pełny status połączenia
    func checkConnectionStatus() async -> WatchConnectivityStatus
    
    func stopWatchConnectivity() async
    
}
